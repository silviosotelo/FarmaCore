(function ($) {
  "use strict";

	$(document).ready(function() {
	
		var singleCartPos = $('.single-wrapper .single_add_to_cart_button').offset();
		var singleCartTop = $('.single-wrapper .single_add_to_cart_button').length && $(".bacola-product-bottom-popup-cart").length ? singleCartPos.top : 0;

		$(window).on("scroll", function () {

			if ( $(".bacola-product-bottom-popup-cart").length && $(".single_add_to_cart_button").length ) {
								
				if ( $(window).scrollTop() > singleCartTop ) {
					$(".bacola-product-bottom-popup-cart").addClass('active');
					$(".bacola-product-bottom-popup-cart").addClass('sticky-add-to-cart');

				} else {
					$(".bacola-product-bottom-popup-cart").removeClass('active');
				}

			}

		});
		
		
		$(".sticky_add_to_cart").click(function () {
		   //1 second of animation time
		   //html works for FFX but not Chrome
		   //body works for Chrome but not FFX
		   //This strange selector seems to work universally
		   $("html, body").animate({scrollTop: 0}, 800);
		});

		
	});
	
}(jQuery));