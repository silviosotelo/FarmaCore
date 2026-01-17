<?php

namespace Elementor;

class Bacola_Category_Banner2_Widget extends Widget_Base {
    use Bacola_Helper;
	
    public function get_name() {
        return 'bacola-category-banner2';
    }
    public function get_title() {
        return 'Category Banner 2 (K)';
    }
    public function get_icon() {
        return 'eicon-slider-push';
    }
    public function get_categories() {
        return [ 'bacola' ];
    }

	protected function register_controls() {

		$this->start_controls_section(
			'content_section',
			[
				'label' => esc_html__( 'Content', 'bacola-core' ),
				'tab' => Controls_Manager::TAB_CONTENT,
			]
		);
		
        $this->add_control( 'title',
            [
                'label' => esc_html__( 'Title', 'bacola-core' ),
                'type' => Controls_Manager::TEXT,
                'default' => 'NEW PRODUCTS',
                'description'=> 'Add a title.',
				'label_block' => true,
            ]
        );
		
        $this->add_control( 'subtitle',
            [
                'label' => esc_html__( 'Subtitle', 'bacola-core' ),
                'type' => Controls_Manager::TEXT,
                'default' => 'New products with updated stocks.',
                'description'=> 'Add a subtitle.',
				'label_block' => true,
            ]
        );
		
        $this->add_control( 'btn_title',
            [
                'label' => esc_html__( 'Button Title', 'bacola-core' ),
                'type' => Controls_Manager::TEXT,
                'label_block' => true,
                'default' => 'View All',
                'pleaceholder' => esc_html__( 'Enter button title here', 'bacola-core' )
            ]
        );
		
        $this->add_control( 'btn_link',
            [
                'label' => esc_html__( 'Button Link', 'bacola-core' ),
                'type' => Controls_Manager::URL,
                'label_block' => true,
                'placeholder' => esc_html__( 'Place URL here', 'bacola-core' )
            ]
        );
		

		
		$this->end_controls_section();
		/*****   END CONTROLS SECTION   ******/

		/***** START QUERY CONTROLS SECTION *****/
		$this->bacola_query_elementor_controls($post_count = 6, $column = 3);
		/***** END QUERY CONTROLS SECTION *****/

        /*****   START CONTROLS SECTION   ******/
		$this->start_controls_section(
			'banner_section',
			[
				'label' => esc_html__( 'Banner', 'bacola-core' ),
				'tab' => Controls_Manager::TAB_CONTENT,
			]
		);
		
		$defaultimage = plugins_url( 'images/category-banner2.jpg', __DIR__ );
		
        $this->add_control( 'image',
            [
                'label' => esc_html__( 'Image', 'bacola-core' ),
                'type' => Controls_Manager::MEDIA,
                'default' => ['url' => $defaultimage],
            ]
        );
		
        $this->add_control( 'banner_title',
            [
                'label' => esc_html__( 'Banner Title', 'bacola-core' ),
                'type' => Controls_Manager::TEXTAREA,
                'default' => 'The freshest of',
                'description'=> 'Add a title.',
				'label_block' => true,
            ]
        );
		
        $this->add_control( 'banner_subtitle',
            [
                'label' => esc_html__( 'Banner Subtitle', 'bacola-core' ),
                'type' => Controls_Manager::TEXT,
                'default' => 'all products',
                'description'=> 'Add a subtitle.',
				'label_block' => true,
            ]
        );
		
        $this->add_control( 'banner_second_subtitle',
            [
                'label' => esc_html__( 'Banner Second Subtitle', 'bacola-core' ),
                'type' => Controls_Manager::TEXT,
                'default' => 'Just in Bacola',
                'description'=> 'Add a subtitle.',
				'label_block' => true,
            ]
        );
		
        $this->add_control( 'banner_slogan',
            [
                'label' => esc_html__( 'Banner Slogan', 'bacola-core' ),
                'type' => Controls_Manager::TEXT,
                'default' => 'delicious',
                'description'=> 'Add a subtitle.',
				'label_block' => true,
            ]
        );
		
        $this->add_control( 'banner_btn_link',
            [
                'label' => esc_html__( 'Button Link', 'bacola-core' ),
                'type' => Controls_Manager::URL,
                'label_block' => true,
                'placeholder' => esc_html__( 'Place URL here', 'bacola-core' )
            ]
        );
		
		/*****   END CONTROLS SECTION   ******/
        /*****   START CONTROLS SECTION   ******/
		
		$this->end_controls_section();
		$this->start_controls_section('bacola_styling',
            [
                'label' => esc_html__( ' Style', 'bacola-core' ),
                'tab' => Controls_Manager::TAB_STYLE
            ]
        );
		
		$this->add_control( 'title_heading',
            [
                'label' => esc_html__( 'TITLE', 'bacola-core' ),
                'type' => Controls_Manager::HEADING,
				'separator' => 'before'
            ]
        );
		
		$this->add_control( 'title_color',
           [
               'label' => esc_html__( 'Title Color', 'bacola-core' ),
               'type' => Controls_Manager::COLOR,
               'default' => '',
               'selectors' => ['{{WRAPPER}} .site-module .module-header .entry-title' => 'color: {{VALUE}};']
           ]
        );
		
		$this->add_control( 'title_hvrcolor',
           [
               'label' => esc_html__( 'Title Hover Color', 'bacola-core' ),
               'type' => Controls_Manager::COLOR,
               'default' => '',
               'selectors' => ['{{WRAPPER}} .site-module .module-header .entry-title:hover' => 'color: {{VALUE}};']
           ]
        );
		
		$this->add_control( 'title_size',
            [
                'label' => esc_html__( 'Size', 'bacola-core' ),
                'type' => Controls_Manager::NUMBER,
                'min' => 0,
                'max' => 100,
                'step' => 1,
                'default' => '',
                'selectors' => [ '{{WRAPPER}} .site-module .module-header .entry-title' => 'font-size: {{SIZE}}px;' ],
            ]
        );
		
		$this->add_responsive_control( 'title_left',
            [
                'label' => esc_html__( 'Left', 'bacola-core' ),
                'type' => Controls_Manager::SLIDER,
                'size_units' => [ 'px', 'vh' ],
                'range' => [
                    'px' => [
                        'min' => 0,
                        'max' => 1000
                    ],
                    'vh' => [
                        'min' => 0,
                        'max' => 100
                    ]
                ],
                'selectors' => [
                    '{{WRAPPER}} .site-module .module-header .entry-title' => 'padding-left: {{SIZE}}{{UNIT}}',
                ]
            ]
        );
		
		$this->add_responsive_control( 'title_top',
            [
                'label' => esc_html__( 'Top', 'bacola-core' ),
                'type' => Controls_Manager::SLIDER,
                'size_units' => [ 'px', 'vh' ],
                'range' => [
                    'px' => [
                        'min' => 0,
                        'max' => 1000
                    ],
                    'vh' => [
                        'min' => 0,
                        'max' => 100
                    ]
                ],
                'selectors' => [
                    '{{WRAPPER}} .site-module .module-header .entry-title' => 'padding-top: {{SIZE}}{{UNIT}}',
                ]
            ]
        );
		
		$this->add_control( 'title_opacity_important_style',
            [
                'label' => esc_html__( 'Opacity', 'bacola-core' ),
                'type' => Controls_Manager::NUMBER,
                'min' => 0,
                'max' => 1,
                'step' => 0.1,
                'default' => '',
                'selectors' => ['{{WRAPPER}} .site-module .module-header .entry-title' => 'opacity: {{VALUE}} ;'],
            ]
        );
		
		$this->add_group_control(
            Group_Control_Typography::get_type(),
            [
                'name' => 'title_typo',
                'label' => esc_html__( 'Typography', 'bacola-core' ),

                'selector' => '{{WRAPPER}} .site-module .module-header .entry-title'
            ]
        );
		
		$this->add_control( 'subtitle_heading',
            [
                'label' => esc_html__( 'SUBTITLE', 'bacola-core' ),
                'type' => Controls_Manager::HEADING,
				'separator' => 'before'
            ]
        );
		
		$this->add_control( 'subtitle_color',
           [
               'label' => esc_html__( 'Subtitle Color', 'bacola-core' ),
               'type' => Controls_Manager::COLOR,
               'default' => '',
               'selectors' => ['{{WRAPPER}} .site-module .module-header .entry-description' => 'color: {{VALUE}};']
           ]
        );
		
		$this->add_control( 'subtitle_hvrcolor',
           [
               'label' => esc_html__( 'Subtitle Hover Color', 'bacola-core' ),
               'type' => Controls_Manager::COLOR,
               'default' => '',
               'selectors' => ['{{WRAPPER}} .site-module .module-header .entry-description:hover' => 'color: {{VALUE}};']
           ]
        );
		
		$this->add_control( 'subtitle_size',
            [
                'label' => esc_html__( 'Subtitle Size', 'bacola-core' ),
                'type' => Controls_Manager::NUMBER,
                'min' => 0,
                'max' => 100,
                'step' => 1,
                'default' => '',
                'selectors' => [ '{{WRAPPER}} .site-module .module-header .entry-description' => 'font-size: {{SIZE}}px;' ],
            ]
        );
		
		$this->add_responsive_control( 'subtitle_left',
            [
                'label' => esc_html__( 'Left', 'bacola-core' ),
                'type' => Controls_Manager::SLIDER,
                'size_units' => [ 'px', 'vh' ],
                'range' => [
                    'px' => [
                        'min' => 0,
                        'max' => 1000
                    ],
                    'vh' => [
                        'min' => 0,
                        'max' => 100
                    ]
                ],
                'selectors' => [
                    '{{WRAPPER}} .site-module .module-header .entry-description' => 'padding-left: {{SIZE}}{{UNIT}}',
                ]
            ]
        );
		
		$this->add_responsive_control( 'subtitle_top',
            [
                'label' => esc_html__( 'Top', 'bacola-core' ),
                'type' => Controls_Manager::SLIDER,
                'size_units' => [ 'px', 'vh' ],
                'range' => [
                    'px' => [
                        'min' => 0,
                        'max' => 1000
                    ],
                    'vh' => [
                        'min' => 0,
                        'max' => 100
                    ]
                ],
                'selectors' => [
                    '{{WRAPPER}} .site-module .module-header .entry-description' => 'padding-top: {{SIZE}}{{UNIT}}',
                ]
            ]
        );
		
		$this->add_control( 'subtitle_opacity_important_style',
            [
                'label' => esc_html__( 'Opacity', 'bacola-core' ),
                'type' => Controls_Manager::NUMBER,
                'min' => 0,
                'max' => 1,
                'step' => 0.1,
                'default' => '',
                'selectors' => ['{{WRAPPER}} .site-module .module-header .entry-description' => 'opacity: {{VALUE}} ;'],
            ]
        );
		
		$this->add_group_control(
            Group_Control_Typography::get_type(),
            [
                'name' => 'subtitle_typo',
                'label' => esc_html__( 'Typography', 'bacola-core' ),

                'selector' => '{{WRAPPER}} .module-header .entry-description'
            ]
        );
		
		$this->end_controls_tab();
        $this->end_controls_tabs();
        $this->end_controls_section();
		/*****   END CONTROLS SECTION   ******/
        /*****   START CONTROLS SECTION   ******/
        $this->start_controls_section('btn_styling',
            [
                'label' => esc_html__( ' Button Style', 'bacola-core' ),
                'tab' => Controls_Manager::TAB_STYLE
            ]
        );
		
		$this->add_responsive_control( 'btn_padding',
            [
                'label' => esc_html__( 'Padding', 'bacola-core' ),
                'type' => Controls_Manager::DIMENSIONS,
                'size_units' => [ 'px' ],
                'selectors' => ['{{WRAPPER}}  .site-module .module-header .column .button' => 'padding: {{TOP}}{{UNIT}} {{RIGHT}}{{UNIT}} {{BOTTOM}}{{UNIT}} {{LEFT}}{{UNIT}};'],              
            ]
        );
		
		$this->add_responsive_control( 'btn_right',
            [
                'label' => esc_html__( 'Right', 'bacola-core' ),
                'type' => Controls_Manager::SLIDER,
                'size_units' => [ 'px', 'vh' ],
                'range' => [
                    'px' => [
                        'min' => 0,
                        'max' => 1000
                    ],
                    'vh' => [
                        'min' => 0,
                        'max' => 100
                    ]
                ],
                'selectors' => [
                    '{{WRAPPER}}  .site-module .module-header .column .button' => 'margin-right: {{SIZE}}{{UNIT}}',
                ]
            ]
        );
		
		$this->add_responsive_control( 'btn_top',
            [
                'label' => esc_html__( 'Top', 'bacola-core' ),
                'type' => Controls_Manager::SLIDER,
                'size_units' => [ 'px', 'vh' ],
                'range' => [
                    'px' => [
                        'min' => 0,
                        'max' => 1000
                    ],
                    'vh' => [
                        'min' => 0,
                        'max' => 100
                    ]
                ],
                'selectors' => [
                    '{{WRAPPER}}  .site-module .module-header .column .button' => 'margin-top: {{SIZE}}{{UNIT}}',
                ]
            ]
        );
		
		$this->add_control( 'btn_opacity_important_style',
            [
                'label' => esc_html__( 'Opacity', 'bacola-core' ),
                'type' => Controls_Manager::NUMBER,
                'min' => 0,
                'max' => 1,
                'step' => 0.1,
                'default' => '',
                'selectors' => ['{{WRAPPER}} .site-module .module-header .column .button' => 'opacity: {{VALUE}} ;'],
            ]
        );
  	    
		$this->add_group_control(
            Group_Control_Typography::get_type(),
            [
                'name' => 'btn_typo',
                'label' => esc_html__( 'Typography', 'bacola-core' ),

                'selector' => '{{WRAPPER}} .site-module .module-header .column .button '
            ]
        );

		$this->start_controls_tabs('btn_tabs');
        $this->start_controls_tab( 'btn_normal_tab',
            [ 'label' => esc_html__( 'Normal', 'bacola-core' ) ]
        );
		
		$this->add_control( 'btn_color',
            [
                'label' => esc_html__( 'Color', 'bacola-core' ),
                'type' => Controls_Manager::COLOR,
                'default' => '',
                'selectors' => ['{{WRAPPER}} .site-module .module-header .column .button ' => 'color: {{VALUE}};']
            ]
        );
       
	    $this->add_group_control(
            Group_Control_Border::get_type(),
            [
                'name' => 'btn_border',
                'label' => esc_html__( 'Border', 'bacola-core' ),
                'selector' => '{{WRAPPER}} .site-module .module-header .column .button',
            ]
        );
        
		$this->add_responsive_control( 'btn_border_radius',
            [
                'label' => esc_html__( 'Border Radius', 'bacola-core' ),
                'type' => Controls_Manager::DIMENSIONS,
                'size_units' => [ 'px' ],
                'selectors' => ['{{WRAPPER}} .site-module .module-header .column .button ' => 'border-radius: {{TOP}}{{UNIT}} {{RIGHT}}{{UNIT}} {{BOTTOM}}{{UNIT}} {{LEFT}}{{UNIT}} !important;'],
            ]
        );
       
		$this->add_control( 'btn_bgclr',
           [
               'label' => esc_html__( 'Background Color', 'bacola-core' ),
               'type' => Controls_Manager::COLOR,
               'default' => '',
               'selectors' => [
					'{{WRAPPER}} .site-module .module-header .column .button' => 'background-color: {{VALUE}};'
               ]
           ]
        );
       
		$this->end_controls_tab();
        $this->start_controls_tab('btn_hover_tab',
            [ 'label' => esc_html__( 'Hover', 'bacola-core' ) ]
        );
       
	    $this->add_control( 'btn_hvrcolor',
            [
                'label' => esc_html__( 'Color', 'bacola-core' ),
                'type' => Controls_Manager::COLOR,
                'default' => '',
                'selectors' => ['{{WRAPPER}} .site-module .module-header .column .button:hover ' => 'color: {{VALUE}};']
            ]
        );
       
	    $this->add_group_control(
            Group_Control_Border::get_type(),
            [
                'name' => 'btn_hvrborder',
                'label' => esc_html__( 'Border', 'bacola-core' ),
                'selector' => '{{WRAPPER}} .site-module .module-header .column .button:hover',
            ]
        );
		
		$this->add_control( 'btn_hvrbgclr',
           [
               'label' => esc_html__( 'Background Hover Color', 'bacola-core' ),
               'type' => Controls_Manager::COLOR,
               'default' => '',
               'selectors' => [
					'{{WRAPPER}} .site-module .module-header .column .button:hover' => 'background-color: {{VALUE}};'
               ]
           ]
        );
		
		$this->end_controls_section();
		
	}

	protected function render() {
		$settings = $this->get_settings_for_display();
		$target = $settings['btn_link']['is_external'] ? ' target="_blank"' : '';
		$nofollow = $settings['btn_link']['nofollow'] ? ' rel="nofollow"' : '';
		$bannertarget = $settings['banner_btn_link']['is_external'] ? ' target="_blank"' : '';
		$bannernofollow = $settings['banner_btn_link']['nofollow'] ? ' rel="nofollow"' : '';
		
		$output = '';
		
		$terms = get_terms( array(
			'taxonomy' => 'product_cat',
			'hide_empty' => true,
			'parent'    => 0,
			'include'   => $settings['cat_filter'],
			'order'          => $settings['order'],
			'orderby'        => $settings['orderby']
		) );


		
		$term_children = get_term_children( implode(' ',$settings['cat_filter']), 'product_cat' );
		$catlink = get_term_link( intval(implode(' ',$settings['cat_filter'])), 'product_cat' );
		$term = get_term( implode(' ',$settings['cat_filter']), 'product_cat' );
		$term_name = $term->name;

		
		$output .= '<div class="site-module module-categor-products style-3">';
			  
		if($settings['title'] || $settings['subtitle']){
		$output .= '<div class="module-header">';
		$output .= '<div class="column">';
		$output .= '<h4 class="entry-title">'.esc_html($settings['title']).'</h4>';
		$output .= '<div class="entry-description">'.esc_html($settings['subtitle']).'</div>';
		$output .= '</div><!-- column -->';
		$output .= '<div class="column">';
		$output .= '<a href="'.esc_url($settings['btn_link']['url']).'" '.esc_attr($target.$nofollow).' class="button button-info-default xsmall rounded">'.esc_html($settings['btn_title']).' <i class="klbth-icon-right-arrow"></i></a>';
		$output .= '</div><!-- column -->';
		$output .= '</div><!-- module-header -->';
		}

		$output .= '<div class="module-body">';
		$output .= '<div class="column left">';
		$output .= '<div class="cell list">';
		if($term_children){
			$output .= '<div class="categories-links">';
			$output .= '<ul>';
			foreach($term_children as $child){
				$childterm = get_term_by( 'id', $child, 'product_cat' );
				
				$output .= '<li><a href="'.esc_url(get_term_link( $child )).'">'.esc_html($childterm->name).'</a></li>';
			}
			$output .= '</ul>';
			$output .= '</div>';
		}
		$output .= '</div><!-- cell -->';
		
		$output .= '<div class="cell banner">';
		$output .= '<div class="module-banner image align-left align-top full-text">';
		$output .= '<div class="module-body">';
		$output .= '<div class="banner-wrapper">';
		$output .= '<div class="banner-content">';
		$output .= '<div class="content-header">';
		$output .= '<div class="category-text color-danger">'.esc_html($settings['banner_slogan']).'</div>';
		$output .= '</div><!-- content-header -->';
		$output .= '<div class="content-main">';
		$output .= '<h4 class="entry-subtitle color-text xlight">'.bacola_sanitize_data($settings['banner_title']).'</h4>';
		$output .= '<h3 class="entry-title color-text-light">'.esc_html($settings['banner_subtitle']).'</h3>';
		$output .= '<div class="entry-store color-info-dark">'.esc_html($settings['banner_second_subtitle']).'</div>';
		$output .= '</div><!-- content-main -->';
		$output .= '</div><!-- banner-content -->';
		$output .= '<div class="banner-thumbnail">';
		$output .= '<img src="'.esc_url($settings['image']['url']).'">';
		$output .= '</div><!-- banner-thumbnail -->';
		$output .= '<a href="'.esc_url($settings['banner_btn_link']['url']).'" '.esc_attr($target.$nofollow).' class="overlay-link"></a>';
		$output .= '</div><!-- banner-wrapper -->';
		$output .= '</div><!-- module-body -->';
		$output .= '</div><!-- site-module -->';
		$output .= '</div><!-- cell -->';
		$output .= '</div><!-- column -->';
		$output .= '<div class="column right">';
		$output .= '<div class="products mobile-column-'.esc_attr($settings['mobile_column']).' column-'.esc_attr($settings['column']).'">';	  
				  
		$output .= $this->bacola_elementor_product_loop($settings);

		$output .= '</div><!-- products -->';
		$output .= '</div><!-- column -->';
		$output .= '</div><!-- module-body -->';
		$output .= '</div><!-- site-module -->';

		echo $output;

		
	}

}
