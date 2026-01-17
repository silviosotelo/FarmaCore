(function ($) {
  "use strict";
	
	$(document).ready(function() {
		
		$(document).on('click', 'input.klbicon-picker', function(event){
			event.preventDefault(); 
			$(this).closest('.bacola-field-iconfield').find('.klb-iconsholder-wrapper').slideToggle();
		});
		
		
		$(document).on('click', '.klb-iconbox', function(event){	
			$(this).closest('.bacola-field-iconfield').find('input.klbicon-picker').val($(this).find('i').attr('class'));
			$(this).closest('.bacola-field-iconfield').find('.klb-iconsholder-wrapper').slideToggle();
		});
		
		
		var klbicon = 'klbth-icon-location klbth-icon-4-grid klbth-icon-2-grid klbth-icon-3-grid klbth-icon-left-arrow klbth-icon-list-grid klbth-icon-grid klbth-icon-user klbth-icon-search klbth-icon-boiled-egg klbth-icon-cleaning-products klbth-icon-bread klbth-icon-hammer klbth-icon-milk klbth-icon-cheese-3 klbth-icon-chips klbth-icon-juice klbth-icon-pumpkin klbth-icon-lipstick klbth-icon-vegan klbth-icon-gluten-free klbth-icon-soap klbth-icon-toothpaste klbth-icon-wheat klbth-icon-baby-food klbth-icon-water klbth-icon-doughnut klbth-icon-biscuit klbth-icon-diaper klbth-icon-toilet-paper klbth-icon-cake klbth-icon-dog-food klbth-icon-bar klbth-icon-cleaning-products-1 klbth-icon-canned klbth-icon-apple-juice klbth-icon-ice-cream klbth-icon-freezer klbth-icon-bottle klbth-icon-condom klbth-icon-candy klbth-icon-meat-2 klbth-icon-pill klbth-icon-pan klbth-icon-bug-spray klbth-icon-jam-1 klbth-icon-banana klbth-icon-coconut klbth-icon-pet klbth-icon-chicken klbth-icon-baby-bottle klbth-icon-flour klbth-icon-toast klbth-icon-watermelon klbth-icon-carrot klbth-icon-jam klbth-icon-fish klbth-icon-cupcake klbth-icon-discount-2 klbth-icon-beer klbth-icon-beverage klbth-icon-breakfast klbth-icon-broom klbth-icon-cappuccino klbth-icon-cleaning-robot klbth-icon-cleaning-spray klbth-icon-meat-1 klbth-icon-scoop klbth-icon-toasted-beer klbth-icon-heart klbth-icon-shopping-bag-grossery klbth-icon-heart-empty klbth-icon-cashier klbth-icon-scale klbth-icon-star klbth-icon-star-empty klbth-icon-toothbrush klbth-icon-star-half klbth-icon-sausage klbth-icon-mail klbth-icon-cheese klbth-icon-discount klbth-icon-electricity klbth-icon-fish-1 klbth-icon-sardines klbth-icon-delivery-truck-2 klbth-icon-armchair klbth-icon-baby-boy klbth-icon-baby-carriage klbth-icon-baking-products klbth-icon-bathtub klbth-icon-bleach-and-soup klbth-icon-dollar klbth-icon-butter klbth-icon-home-icon klbth-icon-canned-soup klbth-icon-heart-1 klbth-icon-cardiogram klbth-icon-cereal klbth-icon-cheese-1 klbth-icon-home klbth-icon-chef klbth-icon-cooking klbth-icon-cup klbth-icon-cutlery klbth-icon-cutlery-1 klbth-icon-electronics klbth-icon-floss klbth-icon-intersex klbth-icon-kitchen-glove klbth-icon-kitchen-pack-1 klbth-icon-kitchen-pack klbth-icon-kitchen klbth-icon-lamp klbth-icon-living-room klbth-icon-meat klbth-icon-monitor klbth-icon-oatmeal klbth-icon-pacifier klbth-icon-pancake klbth-icon-perfume klbth-icon-pizza klbth-icon-preserves klbth-icon-puzzle klbth-icon-ready-to-eat klbth-icon-rice klbth-icon-sandwiches klbth-icon-sausage-and-ham klbth-icon-snowflake klbth-icon-soft-drinks klbth-icon-spices klbth-icon-stew klbth-icon-stroller klbth-icon-sweets klbth-icon-syrups klbth-icon-t-shirt klbth-icon-toothbrush-1 klbth-icon-tree klbth-icon-vegetables klbth-icon-yogurt klbth-icon-filter klbth-icon-store klbth-icon-x klbth-icon-full-screen klbth-icon-sort klbth-icon-discount-outline klbth-icon-phone-call klbth-icon-mobile-phone klbth-icon-clock klbth-icon-download klbth-icon-online-shop klbth-icon-stopwatch klbth-icon-help-circled klbth-icon-marketing-online klbth-icon-info-circled klbth-icon-buy-phone klbth-icon-buy-click klbth-icon-buy klbth-icon-packing-list klbth-icon-delivery-box-1 klbth-icon-fast-delivery klbth-icon-package-check klbth-icon-new-product klbth-icon-package klbth-icon-delivery-hand klbth-icon-milk-box klbth-icon-box klbth-icon-virus klbth-icon-delivery klbth-icon-bookmark klbth-icon-right-arrow klbth-icon-discount-1 klbth-icon-down-open klbth-icon-food-delivery klbth-icon-groceries klbth-icon-menu-thin klbth-icon-discount-elipse klbth-icon-shopping-bag klbth-icon-secure klbth-icon-potato-chips-1 klbth-icon-dairy-products klbth-icon-fish-2 klbth-icon-flour-1 klbth-icon-canned-food klbth-icon-potato-chips klbth-icon-down-dir klbth-icon-up-dir klbth-icon-left-dir klbth-icon-right-dir klbth-icon-left-open klbth-icon-right-open klbth-icon-up-open klbth-icon-down-open-mini klbth-icon-fire klbth-icon-plus klbth-icon-yahoo klbth-icon-ebay klbth-icon-minus klbth-icon-forward klbth-icon-thumbs-up-1 klbth-icon-thumbs-down-1 klbth-icon-code klbth-icon-export klbth-icon-quote klbth-icon-cog klbth-icon-popup klbth-icon-resize-full-1 klbth-icon-left-open-mini klbth-icon-right-open-mini klbth-icon-up-open-mini klbth-icon-down-open-big klbth-icon-left-open-big klbth-icon-right-open-big klbth-icon-up-open-big klbth-icon-play klbth-icon-stop klbth-icon-pause klbth-icon-record klbth-icon-flash klbth-icon-paper-plane klbth-icon-leaf klbth-icon-dot-3 klbth-icon-ok klbth-icon-cancel klbth-icon-openid klbth-icon-yelp klbth-icon-pocket klbth-icon-shuffle klbth-icon-block klbth-icon-link klbth-icon-phone-circled klbth-icon-phone klbth-icon-picture klbth-icon-camera klbth-icon-video klbth-icon-thumbs-up klbth-icon-thumbs-down klbth-icon-volume-up klbth-icon-user-1 klbth-icon-wallet-1 klbth-icon-credit-card-2 klbth-icon-wallet-2 klbth-icon-invoice klbth-icon-delivery-truck klbth-icon-gift klbth-icon-bookmark-empty klbth-icon-twitter klbth-icon-facebook klbth-icon-github klbth-icon-rss klbth-icon-mail-alt klbth-icon-linkedin klbth-icon-coffee klbth-icon-laptop klbth-icon-tablet klbth-icon-circle-empty klbth-icon-circle klbth-icon-star-half-alt klbth-icon-unlink klbth-icon-maxcdn klbth-icon-youtube klbth-icon-stackoverflow klbth-icon-instagram klbth-icon-tumblr klbth-icon-apple klbth-icon-android klbth-icon-dribbble klbth-icon-skype klbth-icon-foursquare klbth-icon-vkontakte klbth-icon-dot-circled klbth-icon-slack klbth-icon-google klbth-icon-reddit klbth-icon-stumbleupon klbth-icon-delicious klbth-icon-digg klbth-icon-paw klbth-icon-behance klbth-icon-spotify klbth-icon-deviantart klbth-icon-soundcloud klbth-icon-vine klbth-icon-sliders klbth-icon-soccer-ball klbth-icon-twitch klbth-icon-paypal klbth-icon-gwallet klbth-icon-visa klbth-icon-mastercard klbth-icon-discover klbth-icon-amex klbth-icon-paypal-card klbth-icon-stripe klbth-icon-dashcube klbth-icon-forumbee klbth-icon-venus-mars klbth-icon-pinterest klbth-icon-whatsapp klbth-icon-medium klbth-icon-500px klbth-icon-amazon klbth-icon-vimeo klbth-icon-credit-card-1 klbth-icon-codiepie klbth-icon-percent klbth-icon-snapchat klbth-icon-quora klbth-icon-flickr klbth-icon-smashing',
			klbiconArray = klbicon.split(' '); // creating array

		// This loop will add icons inside BOX
		for (var i = 0; i < klbiconArray.length; i++) {
			jQuery(".klb-iconsholder").append('<div class="klb-iconbox"><p class="icon"><i class="' + klbiconArray[i] + '"></i>'+klbiconArray[i]+'</p></div>');
		}

		var timeout;
		$("input.iconsearch").on("keyup", function() {
			if(timeout) {
				clearTimeout(timeout);
			}
			
			var value = this.value.toLowerCase().trim();
			var iconbox = $(this).closest('.bacola-field-iconfield').find('.klb-iconbox');
			timeout = setTimeout(function() {
			  $(iconbox).show().filter(function() {
				return $(this).text().toLowerCase().trim().indexOf(value) == -1;
			  }).hide();
			}, 500);
		});

	});

})(jQuery);
