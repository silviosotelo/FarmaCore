<?php
/*************************************************
## Scripts
*************************************************/
function bacola_maintenance_scripts() {
	wp_register_style( 'klb-maintenance',    plugins_url( 'css/maintenance.css', __FILE__ ), false, '1.0');
}
add_action( 'wp_enqueue_scripts', 'bacola_maintenance_scripts' );

function bacola_maintenance_mode() {
	if (current_user_can('edit_themes') || is_user_logged_in()) {
		return;
	}
	
	// Disable Newsletter Popup
	add_filter( 'bacola_newsletter_filter',  '__return_false' );

	// Get Maintenance CSS
	wp_enqueue_style('klb-maintenance');

	// Get WP Head
	wp_head();
	
	echo '<div class="maintenance-mode-wrapper">';
	echo '<div class="maintenance-content">';
	echo '<h2 class="entry-title">'.esc_html(get_theme_mod('bacola_maintenance_title','Coming')).'</h2>';
	echo '<h1 class="entry-sub"> '.esc_html(get_theme_mod('bacola_maintenance_second_title','Soon')).' </h1>';
	echo '<p>'.esc_html(get_theme_mod('bacola_maintenance_subtitle','Get ready! Something really cool is coming!')).'</p>';
				
	echo '<div class="maintenance-form">';
	echo do_shortcode('[mc4wp_form id="'.get_theme_mod('bacola_maintenance_mailchimp_formid').'"]');
	echo '</div>';
	echo '</div>';
	if(get_theme_mod( 'bacola_maintenance_image' )){
		echo '<img src="'.esc_url( wp_get_attachment_url(get_theme_mod( 'bacola_maintenance_image' )) ).'" alt="'.esc_attr__('maintenance','bacola-core').'">';
	} else {
		echo '<img src="'.plugins_url( 'img/maintenance.png', __FILE__ ).'" alt="'.esc_attr__('maintenance','bacola-core').'">';
	}
	
	echo '</div>';

	// Get WP Footer
	wp_footer();
	
	wp_die();
	
}
add_action('get_header', 'bacola_maintenance_mode');