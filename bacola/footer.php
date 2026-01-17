<?php
/**
 * footer.php
 * @package WordPress
 * @subpackage Bacola
 * @since Bacola 1.0
 * 
 */
 ?>
			</div><!-- homepage-content -->
		</div><!-- site-content -->
	</main><!-- site-primary -->

	<?php bacola_do_action( 'bacola_before_main_footer'); ?>

	<?php if ( ! function_exists( 'elementor_theme_do_location' ) || ! elementor_theme_do_location( 'footer' ) ) { ?>
	
		<?php
        /**
        * Hook: bacola_main_footer
        *
        * @hooked bacola_main_footer_function - 10
        */
        do_action( 'bacola_main_footer' );
	
		?>
		
	<?php } ?>
	
	
	<?php bacola_do_action( 'bacola_after_main_footer'); ?>
	
	<div class="site-overlay"></div>

	<?php wp_footer(); ?>
	</body>
</html>