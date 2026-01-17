<?php
/*************************************************
## style and scripts  
*************************************************/ 
function bacola_single_sticky_titles_scripts() {
    wp_register_style('klb-single-sticky-titles', 	  plugins_url( 'css/single-sticky-titles.css', __FILE__ ), false, '1.0');
	wp_register_script( 'klb-single-sticky-titles',   plugins_url( 'js/single-sticky-titles.js',   __FILE__ ), false, '1.0');
}
add_action( 'wp_enqueue_scripts', 'bacola_single_sticky_titles_scripts' );

/*************************************************
## Single Sticky Titles
*************************************************/ 
add_action('woocommerce_after_single_product','bacola_product_single_sticky_titles');
function bacola_product_single_sticky_titles(){
	
	wp_enqueue_style('klb-single-sticky-titles');
	wp_enqueue_script('klb-single-sticky-titles');
	
	echo '<div class="single-sticky-titles">';
	echo '<div class="container"></div>';
	echo '</div>';
}