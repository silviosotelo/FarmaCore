<?php
/**
 * My Account navigation
 *
 * This template can be overridden by copying it to yourtheme/woocommerce/myaccount/navigation.php.
 *
 * HOWEVER, on occasion WooCommerce will need to update template files and you
 * (the theme developer) will need to copy the new files to your theme to
 * maintain compatibility. We try to do this as little as possible, but it does
 * happen. When this occurs the version of the template file will be bumped and
 * the readme will list any important changes.
 *
 * @see     https://docs.woocommerce.com/document/template-structure/
 * @package WooCommerce\Templates
 * @version 9.3.0
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

do_action( 'woocommerce_before_account_navigation' );
?>
<div class="row content-wrapper sidebar-right">
	<div class="col-12 col-md-12 col-lg-12 content-primary">
		<div class="my-account-wrapper"> <!-- my-account-wrapper be closed in myaccount.php -->
			<div class="my-account-navigation"> 
				<div class="account-toggle-menu">
					<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><line x1="2.3" y1="12" x2="21.8" y2="12"></line><line x1="2.3" y1="6" x2="21.8" y2="6"></line><line x1="2.3" y1="18" x2="21.8" y2="18"></line></svg>
					<?php esc_html_e('Navigation','bacola'); ?>
				</div><!-- account-toggle-menu -->
				<nav class="woocommerce-MyAccount-navigation" aria-label="<?php esc_html_e( 'Account pages', 'woocommerce' ); ?>">
					<ul>
						<?php foreach ( wc_get_account_menu_items() as $endpoint => $label ) : ?>
							<li class="<?php echo wc_get_account_menu_item_classes( $endpoint ); ?>">
								<a href="<?php echo esc_url( wc_get_account_endpoint_url( $endpoint ) ); ?>" <?php echo wc_is_current_account_menu_item( $endpoint ) ? 'aria-current="page"' : ''; ?>>
									<?php echo esc_html( $label ); ?>
								</a>
							</li>
						<?php endforeach; ?>
					</ul>
				</nav>
			</div>
<?php do_action( 'woocommerce_after_account_navigation' ); ?>
