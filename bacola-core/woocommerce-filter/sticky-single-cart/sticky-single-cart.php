<?php
/*************************************************
## Scripts
*************************************************/
function bacola_sticky_single_cart_scripts() {
	wp_register_script( 'klb-sticky-single-cart',   plugins_url( 'js/sticky-single-cart.js', __FILE__ ), false, '1.0');
	wp_register_style( 'klb-sticky-single-cart',   plugins_url( 'css/sticky-single-cart.css', __FILE__ ), false, '1.0');
}
add_action( 'wp_enqueue_scripts', 'bacola_sticky_single_cart_scripts' );


/*************************************************
## Sticky add to cart Function
*************************************************/

if ( ! function_exists( 'bacola_sticky_single_cart' ) ) {
    function bacola_sticky_single_cart()
    {
        global $product;
		
		if ( !is_product() || $product->is_type( 'grouped' ) || '0' == bacola_ft( 'bacola_sticky_single_cart', '1' ) ) {
            return;
        }
		
		wp_enqueue_script( 'klb-sticky-single-cart');
		wp_enqueue_style( 'klb-sticky-single-cart');
	
        ?>
        <div id="product-bottom-<?php the_ID(); ?>" <?php wc_product_class( 'bacola-product-bottom-popup-cart', $product ); ?>>
            <div class="container">
                <div class="row">
                    <div class="col-md-6 d-none d-md-flex">
                        <div class="bacola-product-bottom-details">
                            <?php echo get_the_post_thumbnail( $product->get_id(), array(60,60,true) ); ?>
                            <div class="bacola-product-bottom-title">
                                <?php echo get_the_title( $product->get_id() ); ?>
                                <?php woocommerce_template_loop_price(); ?>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-6 " style="text-align: end;">
						<?php if ( $product->is_type( 'simple' ) ) : ?>
							<?php woocommerce_simple_add_to_cart(); ?>
						<?php else : ?>
							<a href="#" class="sticky_add_to_cart single_add_to_cart_button button alt">
								<?php echo true == $product->is_type( 'variable' ) ? esc_html__( 'Select options', 'bacola-core' ) : $product->single_add_to_cart_text(); ?>
							</a>	
						<?php endif; ?>
                    </div>
                </div>
            </div>
        </div>
        <?php
    }
}
add_action( 'bacola_before_main_footer', 'bacola_sticky_single_cart', 10 );
