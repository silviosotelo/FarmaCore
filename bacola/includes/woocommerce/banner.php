<?php $categorybanner = get_theme_mod('bacola_shop_banner_each_category'); ?>
<?php if($categorybanner && is_product_category() && array_search(get_queried_object()->term_id, array_column($categorybanner, 'category_id')) !== false){ ?>
	<?php foreach($categorybanner as $c){ ?>
		<?php if($c['category_id'] == get_queried_object()->term_id){ ?>
		
			<div class="shop-banner">
				<div class="module-banner image align-center align-middle">
					<div class="module-body">
						<div class="banner-wrapper">
							<div class="banner-content">
								<div class="content-main">
									<h4 class="entry-subtitle color-text xlight"><?php echo esc_html($c['category_title']); ?></h4>
									<h3 class="entry-title color-text large"><?php echo bacola_sanitize_data($c['category_subtitle']); ?></h3>
									<div class="entry-text color-info-dark"><?php echo esc_html($c['category_desc']); ?></div>
								</div>
							</div>
							<div class="banner-thumbnail">
								<img src="<?php echo esc_url(bacola_get_image($c['category_image'])); ?>" alt="<?php echo esc_attr($c['category_title']); ?>">
							</div>
							<a href="<?php echo esc_url($c['category_button_url']); ?>" class="overlay-link"></a>
						</div>
					</div>
				</div>
			</div>
		  
		<?php } ?>
	<?php } ?>
<?php } else { ?>
	<?php $banner = get_theme_mod('bacola_shop_banner_image'); ?>
	<?php $bannertitle = get_theme_mod('bacola_shop_banner_title'); ?>
	<?php $bannersubtitle = get_theme_mod('bacola_shop_banner_subtitle'); ?>
	<?php $bannerdesc = get_theme_mod('bacola_shop_banner_desc'); ?>
	<?php $bannerbuttonurl = get_theme_mod('bacola_shop_banner_button_url'); ?>
	<?php if($banner){ ?>
	
	<div class="shop-banner">
		<div class="module-banner image align-center align-middle">
			<div class="module-body">
				<div class="banner-wrapper">
					<div class="banner-content">
						<div class="content-main">
							<h4 class="entry-subtitle color-text xlight"><?php echo esc_html($bannertitle); ?></h4>
							<h3 class="entry-title color-text large"><?php echo bacola_sanitize_data($bannersubtitle); ?></h3>
							<div class="entry-text color-info-dark"><?php echo esc_html($bannerdesc); ?></div>
						</div>
					</div>
					<div class="banner-thumbnail">
						<img src="<?php echo esc_url(wp_get_attachment_url($banner)); ?>" alt="<?php echo esc_attr($bannertitle); ?>">
					</div>
					<a href="<?php echo esc_url($bannerbuttonurl); ?>" class="overlay-link"></a>
				</div>
			</div>
		</div>
	</div>

	<?php } ?>
<?php } ?>