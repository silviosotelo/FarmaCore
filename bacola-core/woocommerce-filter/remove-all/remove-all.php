<?php

/*************************************************
## Scripts
*************************************************/
function bacola_remove_all_button_scripts() {
	wp_register_script( 'klb-remove-all',   plugins_url( 'js/remove-all.js', __FILE__ ), false, '1.0');
	wp_register_style( 'klb-remove-all',   plugins_url( 'css/remove-all.css', __FILE__ ), false, '1.0');
}
add_action( 'wp_enqueue_scripts', 'bacola_remove_all_button_scripts' );


/*************************************************
## Remove All Button
*************************************************/ 

add_action( 'woocommerce_cart_actions', 'bacola_remove_all_button' );
function bacola_remove_all_button() {
	
	if(!is_cart()){
		return;
	}
	
	wp_enqueue_script( 'klb-remove-all');
	wp_enqueue_style( 'klb-remove-all');
	
	echo '<a href="#" class="button remove-all">'.esc_html__( 'Remove All', 'bacola-core' ).'</a>';
}

add_action( 'wp_ajax_nopriv_remove_all_from_cart', 'bacola_remove_all_from_cart_callback' );
add_action( 'wp_ajax_remove_all_from_cart', 'bacola_remove_all_from_cart_callback' );
function bacola_remove_all_from_cart_callback() {
	WC()->cart->empty_cart();
}