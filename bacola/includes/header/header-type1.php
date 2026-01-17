<header id="masthead" class="site-header desktop-shadow-disable mobile-shadow-enable mobile-nav-enable"
	itemscope="itemscope" itemtype="http://schema.org/WPHeader">
	<?php if (get_theme_mod('bacola_top_header', 0) == 1) { ?>
	<div class="header-top header-wrapper hide-mobile">
		<div class="container">
			<div class="column column-left">
				<nav class="site-menu horizontal">
					<?php
						wp_nav_menu(
							array(
								'theme_location' => 'top-left-menu',
								'container' => '',
								'fallback_cb' => 'show_top_menu',
								'menu_id' => '',
								'menu_class' => 'menu',
								'echo' => true,
								"walker" => '',
								'depth' => 0
							)
						);
						?>
				</nav><!-- site-menu -->
			</div><!-- column-left -->

			<div class="column column-right">

				<!-- popup para elegir sucursal -->
				<?php echo do_shortcode('[woocommerce_multi_inventory_change_inventory select_store_text="Seleccionar Sucursal" your_store_text="Sucursal más cercana: "]') ?>
				<!-- popup para elegir sucursal -->

			</div><!-- column-right -->
		</div><!-- container -->
	</div><!-- header-top -->
	<?php } ?>

	<div class="header-main header-wrapper">
		<div class="container">
			<div class="column column-left">
				<!--div class="header-buttons hide-desktop">
					<div class="header-canvas button-item">
						<a href="#" class="woocommerce-multi-inventory-open-poup">
							<i class="fa-solid fa-location-dot"></i>
						</a>
					</div><!-- button-item -->
				</div--><!-- header-buttons -->



				<div class="header-buttons button-item hide-desktop hide-mobile">
					<a href="#" class="woocommerce-multi-inventory-open-poup">
						<div class="button-icon"><i class="fa-solid fa-location-dot"></i></div>
					</a>
				</div>

				<div class="header-buttons button-item hide-desktop">
					<span class="d-inline-block" tabindex="0" data-toggle="tooltip" title="Sucursales">
						<a href="<?php echo esc_url(home_url("/sucursales")); ?>">
							<div class="button-icon"><i class="fa-solid fa-location-dot"></i></div>
						</a>
					</span>
				</div>




				<div class="site-brand">
					<a href="<?php echo esc_url(home_url("/")); ?>" title="
						<?php bloginfo("name"); ?>">
						<?php if (get_theme_mod('bacola_logo')) { ?>
						<img class="desktop-logo hide-mobile"
							src="<?php echo esc_url(wp_get_attachment_url(get_theme_mod('bacola_logo'))); ?>"
							alt="<?php bloginfo(" name"); ?>">
						<?php } elseif (get_theme_mod('bacola_logo_text')) { ?>
						<span class="brand-text hide-mobile">
							<?php echo esc_html(get_theme_mod('bacola_logo_text')); ?>
						</span>
						<?php } else { ?>
						<img class="desktop-logo hide-mobile"
							src="<?php echo get_template_directory_uri(); ?>/assets/images/bacola-logo.png" width="164"
							height="44" alt="<?php bloginfo(" name"); ?>">
						<?php } ?>

						<?php if (get_theme_mod('bacola_mobile_logo')) { ?>
						<img class="mobile-logo hide-desktop"
							src="<?php echo esc_url(wp_get_attachment_url(get_theme_mod('bacola_mobile_logo'))); ?>"
							alt="<?php bloginfo(" name"); ?>">
						<?php } else { ?>
						<img class="mobile-logo hide-desktop"
							src="<?php echo get_template_directory_uri(); ?>/assets/images/bacola-logo-mobile.png"
							alt="<?php bloginfo(" name"); ?>">
						<?php } ?>
						<?php if (get_theme_mod('bacola_logo_desc')) { ?>
						<span class="brand-description">
							<?php echo esc_html(get_theme_mod('bacola_logo_desc')); ?>
						</span>
						<?php } ?>
					</a>
				</div><!-- site-brand -->
			</div><!-- column -->
			<div class="column column-center">

				<?php $sidebarmenu = get_theme_mod('bacola_header_sidebar', '0'); ?>

				<?php if ($sidebarmenu == '1') { ?>
				<div class="all-categories locked hide-mobile">
					<a href="#" data-toggle="collapse" data-target="#all-categories">
						<i class="klbth-icon-menu-thin"></i>
						<span class="text">
							<?php esc_html_e('Categorías', 'bacola'); ?>
						</span>
					</a>

					<?php $menu_collapse = is_front_page() && !get_theme_mod('bacola_header_sidebar_collapse') ? 'show' : ''; ?>
					<!--div class="dropdown-categories collapse" id="all-categories">
							<?php
							wp_nav_menu(
								array(
									'theme_location' => 'sidebar-menu',
									'container' => '',
									'fallback_cb' => 'show_top_menu',
									'menu_id' => '',
									'menu_class' => 'menu-list',
									'echo' => true,
									"walker" => new bacola_sidebar_walker(),
									'depth' => 0
								)
							);
							?>
						</div-->

					<div class="dropdown-categories collapse" id="all-categories">
						<ul class="menu-list">
							<?php
		global $wpdb;
		// Obtener las categorías padres que tengan el meta_data "destacado" con valor "1" (true)
		$query = $wpdb->prepare(
			"SELECT t.term_id, t.name
			FROM {$wpdb->terms} t
			INNER JOIN {$wpdb->termmeta} tm ON t.term_id = tm.term_id
			INNER JOIN {$wpdb->term_taxonomy} tt ON t.term_id = tt.term_id
			WHERE tm.meta_key = %s AND tm.meta_value = %d AND tt.parent = 0
			ORDER BY t.name ASC",
			'destacado',
			1
		);

		$categories = $wpdb->get_results($query);

		// Recorrer el resultado y generar el menú solo para las categorías destacadas (con meta_data true)
		foreach ($categories as $category) {
			$category_link = get_category_link($category->term_id);
			echo '<li><a href="' . esc_url($category_link) . '">' . esc_html($category->name) . '</a></li>';
		}
		?>
						</ul>
					</div>


				</div>
				<?php } ?>


				<?php if (get_theme_mod('bacola_header_search', 0) == 1) { ?>
				<div class="header-search">
					<!--<?php if (class_exists('DGWT_WC_Ajax_Search')) { ?>
					<?php echo do_shortcode('[wcas-search-form]'); ?>
					<?php } else { ?>
					<?php echo bacola_header_product_search(); ?>
					<?php } ?>-->
					<!--<?php echo do_shortcode('[fibosearch]'); ?>-->
					<?php echo bacola_header_product_search(); ?>
				</div>
				<?php } ?>
			</div>
			<div class="column column-right">







				<div class="header-buttons">

					<div class="header-cart button-item">
						<span class="d-inline-block" tabindex="0" data-toggle="tooltip" title="Mi cuenta">
							<a href="<?php 
                            // Verificar si el usuario está logueado
                            $user_logged_in = is_user_logged_in();
                            
                            // Definir las URLs de las páginas
                            $cuenta_page_url = site_url('/mi-cuenta/');
                            $login_page_url = site_url('/iniciar-sesion/');
                            $my_account_page_url = site_url('/mi-cuenta/');
                            
                            // Establecer la URL del botón en función del estado de inicio de sesión del usuario
                            $button_url = $user_logged_in ? $my_account_page_url : $login_page_url;

							echo esc_url($cuenta_page_url); 
							?>">
								<div class="button-icon"><i class="fa-solid fa-face-smile-beam"></i></div>
							</a>
						</span>
					</div>

					<!--div class="header-login button-item">
						<span class="d-inline-block" tabindex="0" data-toggle="tooltip" title="Favoritos">
							<a href="<?php echo esc_url(home_url("/mis-favoritos")); ?>">
								<div class="button-icon"><i class="fa-solid fa-heart"></i></div>
							</a>
						</span>
					</div-->

					<div class="header-buttons button-item hide-desktop hide-mobile">
						<span class="d-inline-block" tabindex="0" data-toggle="tooltip" title="Sucursales">
							<a href="<?php echo esc_url(home_url("/sucursales")); ?>" target="_blank">
								<div class="button-icon"><i class="fa-solid fa-location-dot"></i></div>
							</a>
						</span>
					</div>

					<!--div class="header-search-icon button-item hide-desktop hide-mobile">
						<span class="d-inline-block" tabindex="0" data-toggle="tooltip" title="Buscador">
							<a href="#" class="search" id="BotonBuscarHeader">
								<div class="button-icon"><i class="fa-solid fa-search"></i></div>
							</a>
						</span>
					</div-->

					<?php $headercart = get_theme_mod('bacola_header_cart', '0'); ?>
					<?php if ($headercart == '1') { ?>
					<?php global $woocommerce; ?>
					<?php $carturl = wc_get_cart_url(); ?>
					<div class="header-cart button-item">
						<a href="<?php echo esc_url($carturl); ?>">
							<div class="button-icon"><i class="fa-solid fa-bag-shopping"></i></div>
							<span class="cart-count-icon">
								<?php echo sprintf(_n('%d', '%d', $woocommerce->cart->cart_contents_count, 'bacola'), $woocommerce->cart->cart_contents_count); ?>
							</span>
						</a>
						<div class="cart-dropdown hide">
							<div class="cart-dropdown-wrapper">
								<div class="fl-mini-cart-content">
									<?php woocommerce_mini_cart(); ?>
								</div>

								<?php if (get_theme_mod('bacola_header_mini_cart_notice')) { ?>
								<div class="cart-noticy">
									<?php echo esc_html(get_theme_mod('bacola_header_mini_cart_notice')); ?>
								</div><!-- cart-noticy -->
								<?php } ?>
							</div><!-- cart-dropdown-wrapper -->
						</div><!-- cart-dropdown -->
					</div><!-- button-item -->
					<?php } ?>
				</div><!-- header-buttons -->









			</div><!-- column -->
		</div><!-- container -->
	</div><!-- header-main -->



	<div class="header-nav header-wrapper hide-desktop">
		<div class="container">

			<!-- popup para elegir sucursal -->
			<?php echo do_shortcode('[woocommerce_multi_inventory_change_inventory select_store_text="Seleccionar Sucursal" your_store_text="Sucursal más cercana: "]'); ?>
		    <!-- popup para elegir sucursal -->

			<!-- buscador -->
			<?php if (get_theme_mod('bacola_header_search', 0) == 1) { ?>
    		<div class="header-mobile-search" style="width: 100%;">
    			<?php echo bacola_header_product_search(); ?>
    		</div>
    		<?php } ?>
		</div>
		<!-- container -->
	</div>
	<!-- header-nav -->

	<?php do_action('bacola_mobile_bottom_menu'); ?>
</header><!-- site-header -->