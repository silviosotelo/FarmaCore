<?php

/*************************************************
## Scripts
*************************************************/
function bacola_products_navigation_scripts() {
	wp_register_style( 'klb-products-navigation',   plugins_url( 'css/single-products-navigation.css', __FILE__ ), false, '1.0');
}
add_action( 'wp_enqueue_scripts', 'bacola_products_navigation_scripts' );

/*************************************************
## Single Product Nav
*************************************************/ 

if ( ! function_exists( 'bacola_product_nav' ) ) {
	function bacola_product_nav() {
		wp_enqueue_style('klb-products-navigation');
?>

		<div class="klb-products-nav">
			<?php 
				$prev_post = get_previous_post();
				if($prev_post) {
					$prev_title = strip_tags(str_replace('"', '', $prev_post->post_title));
					$prevPrice = wc_get_product( $prev_post );
			
			?>		
				<div class="product-btn product-prev">			
					<a href="<?php echo esc_url( get_permalink( $prev_post->ID ) ); ?>"><span class="product-btn-icon"></span></a>			
					<div class="wrapper-short">
						<div class="product-short">
							<div class="product-short-image">
								<a href="<?php echo esc_url( get_permalink( $prev_post->ID ) ); ?>" class="product-thumb">
									<?php echo apply_filters( 'bacola_products_nav_image', get_the_post_thumbnail( $prev_post, 'thumbnail' ) ); ?>
								</a>
							</div>
							<div class="product-short-description">
								<h3 class="product-title">
									<a href="<?php echo esc_url( get_permalink( $prev_post->ID ) ); ?>">
										<?php echo get_the_title( $prev_post ); ?>
									</a>
								</h3>
								<span class="price">
									<?php echo wp_kses_post( $prevPrice->get_price_html() ); ?>
								</span>
							</div>
						</div>
					</div>
				</div>
			<?php } ?>
			
			
				<a href="<?php echo ( get_permalink( wc_get_page_id( 'shop' ) ) ); ?>" class="klb-back-btn"></a>
			
			<?php 
				
				$next_post = get_next_post();
				if($next_post) {		
					$next_title = strip_tags(str_replace('"', '', $next_post->post_title));
					$nextPrice = wc_get_product( $next_post );
			?>
				<div class="product-btn product-next">
					<a href="<?php echo esc_url( get_permalink( $next_post->ID ) ); ?>"><span class="product-btn-icon"></span></a>
					<div class="wrapper-short">
						<div class="product-short">
							<div class="product-short-image">
								<a href="<?php echo esc_url( get_permalink( $next_post->ID ) ); ?>" class="product-thumb">
									<?php echo apply_filters( 'bacola_products_nav_image', get_the_post_thumbnail( $next_post, 'thumbnail' ) ); ?>
								</a>
							</div>
							<div class="product-short-description">
								<h3 class="product-title">
									<a href="<?php echo esc_url( get_permalink( $next_post->ID ) ); ?>">
										<?php echo get_the_title( $next_post ); ?>
									</a>
								</h3>
								<span class="price">
									<?php echo wp_kses_post( $nextPrice->get_price_html() ); ?>
								</span>
							</div>
						</div>
					</div>
				</div>
			<?php } ?>
		</div>
		
<?php
			
	}
}

add_action( 'klb_woocommerce_after_breadcrumb', 'bacola_product_nav', 2 );