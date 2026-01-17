<?php
/*************************************************
## Ajax Search Scripts
*************************************************/ 
function bacola_ajax_search_scripts() {
	wp_enqueue_style( 'bacola-ajax-search',    plugins_url( 'css/ajax-search.css', __FILE__ ), false, '1.0');
	wp_enqueue_script( 'bacola-ajax-search',    plugins_url( 'js/ajax-search.js', __FILE__ ), false, '1.0');
	wp_localize_script( 'bacola-ajax-search', 'bacolasearch', array(
		'ajaxurl' => esc_url(admin_url( 'admin-ajax.php' )),
	));
}
add_action( 'wp_enqueue_scripts', 'bacola_ajax_search_scripts' );


/*************************************************
## Ajax Login CallBack
*************************************************/ 
add_action( 'wp_ajax_nopriv_ajax_search', 'bacola_ajax_search_callback' );
add_action( 'wp_ajax_ajax_search', 'bacola_ajax_search_callback' );
function bacola_ajax_search_callback() {
	global $wpdb;
	
	$keyword        = esc_html( $_POST['keyword'] );
	
	$clean_term = wc_clean( $keyword );
	$sku_to_id = $wpdb->get_results( "SELECT product_id FROM {$wpdb->wc_product_meta_lookup} WHERE sku LIKE '%{$clean_term}%';", ARRAY_N );

	$args = array(
		'post_type'      => 'product',
		'post_status'    => 'publish',
		'posts_per_page' => 7,
	);
	
	if(!empty($sku_to_id)){
		$args['meta_query'] = array( array(
			'key' => '_sku',
			'value' => $keyword,
			'compare' => 'LIKE'
		) );
	} else {
		$args['s'] = $keyword;
	}

	if ( 'yes' === get_option( 'woocommerce_hide_out_of_stock_items' ) ) {
		$args['tax_query'] = array(
			array(
				'taxonomy' => 'product_visibility',
				'field'    => 'name',
				'terms'    => 'outofstock',
				'operator' => 'NOT IN',
			),
		);
	}

	$args = new WP_Query( $args );

	if ( $args->have_posts() ) {
		echo '<ul>';

		while ( $args->have_posts() ) : $args->the_post();
			$product = wc_get_product( get_the_ID() );
			
			$title = $product->get_name();
			$price = $product->get_price_html();

			if ( ! $product || ( 'trash' === $product->get_status() ) ) {
				continue;
			}
			
			echo '<li>';
			echo '<div class="search-img">';
			echo $product->get_image();
			echo '</div>';
			echo '<div class="search-content">';
			echo '<h1 class="product-title"><a href="'.get_permalink().'" title="'.the_title_attribute( 'echo=0' ).'">'.get_the_title().'</a></h1>';
			echo '<span class="price">'.$price.'</span>';
			echo '</div>';
			echo '</li>';
		endwhile;
		
		if($args->found_posts > 7){
			$searchall = add_query_arg(
				array(
					's' => $keyword, 
					'post_type' => 'product'
				),
				site_url() 
			);
					
			echo '<li class="search-more">';
			echo '<a href="'.esc_url($searchall).'"><span>'.esc_html__('See all products...','bacola-core').'</span> <span>('.esc_html($args->found_posts).')</span></a>';
			echo '</li>';
		}
		
		echo '</ul>';
		wp_reset_postdata();
	} else {
		echo '<ul><li><span>'.sprintf(esc_html__( 'No results found for "%s"', 'bacola-core' ), esc_html( $keyword )).'</span></li></ul>';
	}

	wp_die();

}


/*************************************************
## Search Query For SKU
*************************************************/ 
if ( ! function_exists( 'bacola_sku_search_query' ) ) {
	function bacola_sku_search_query( $where, $s ) {
		global $wpdb;

		$search_ids = array();
		$terms = explode( ',', $s );

		foreach ( $terms as $term ) {
			//Include the search by id if admin area.
			if ( is_admin() && is_numeric( $term ) ) {
				$search_ids[] = $term;
			}
			// search for variations with a matching sku and return the parent.

			$sku_to_parent_id = $wpdb->get_col( $wpdb->prepare( "SELECT p.post_parent as post_id FROM {$wpdb->posts} as p join {$wpdb->wc_product_meta_lookup} ml on p.ID = ml.product_id and ml.sku LIKE '%%%s%%' where p.post_parent <> 0 group by p.post_parent", wc_clean( $term ) ) );

			//Search for a regular product that matches the sku.
			$clean_term = wc_clean( $term );
			$sku_to_id = $wpdb->get_results( "SELECT product_id FROM {$wpdb->wc_product_meta_lookup} WHERE sku LIKE '%{$clean_term}%';", ARRAY_N );

			$sku_to_id_results = array();
			if ( is_array( $sku_to_id ) ) {
				foreach ( $sku_to_id as $id ) {
					$sku_to_id_results[] = $id[0];
				}
			}

			$search_ids = array_merge( $search_ids, $sku_to_id_results, $sku_to_parent_id );
		}

		$search_ids = array_filter( array_map( 'absint', $search_ids ) );

		if ( sizeof( $search_ids ) > 0 ) {
			$where = str_replace( ')))', ")) OR ( {$wpdb->posts}.ID IN (" . implode( ',', $search_ids ) . ")))", $where );
		}

		return $where;
	}
}
 
add_filter( 'posts_search', 'bacola_product_search_sku', 9 );
if ( ! function_exists( 'bacola_product_search_sku' ) ) {
	function bacola_product_search_sku( $where, $class = false ) {
		global $pagenow, $wpdb, $wp;
		
		if ( ( is_admin() ) //if ((is_admin() && 'edit.php' != $pagenow) 

				|| !isset( $wp->query_vars['s'] ) 
				//post_types can also be arrays..
				|| (isset( $wp->query_vars['post_type'] ) && 'product' != $wp->query_vars['post_type'] )
				|| (isset( $wp->query_vars['post_type'] ) && is_array( $wp->query_vars['post_type'] ) && !in_array( 'product', $wp->query_vars['post_type'] ) ) 
				) {
			return $where;
		}

		$s = $wp->query_vars['s'];


		return bacola_sku_search_query( $where, $s );
		
	}
}