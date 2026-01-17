jQuery(document).ready(function($) {
	"use strict";
	
	var searchform = $('header form.search-form');
	var searchinput = $('header form.search-form input[type="search"]');
	var searchbutton = $('header form.search-form button');
	var timeout;

	$(document).on('keyup', 'header form.search-form input[type="search"]', function(event){
		event.preventDefault();

		if($(event.target).val().length < 3){
			return false;
		}
		
		if(timeout) {
			clearTimeout(timeout);
		}
		timeout = setTimeout(function() {
			var data = {
				cache: false,
				type: 'POST',
				action: 'ajax_search',
				beforeSend: function() {
					$(searchbutton).append('<svg class="loader-image preloader" width="65px" height="65px" viewBox="0 0 66 66" xmlns="http://www.w3.org/2000/svg"><circle class="path" fill="none" stroke-width="6" stroke-linecap="round" cx="33" cy="33" r="30"></circle></svg></div>');
					$(searchform).addClass('search-loading');
				},
				keyword: $(event.target).val(),
				
			};

			// since 2.8 ajaxurl is always defined in the admin header and points to admin-ajax.php
			$.post(bacolasearch.ajaxurl, data, function(response) {

				$(".klb-search-results").remove();
				$(searchinput).after('<div class="klb-search-results">' + response + '</div>');

				$(searchform).removeClass('search-loading');
				$(".loader-image").remove();

			});
		}, 500);	
		
    });	
	
	// hide search result box if click outside
	$(document).on('click touch', function(e) {
		// check if ajax is enabled
		if ($('.klb-search-results').length) {
			// show search result when click input
			if($(e.target).is('[type="search"]')){
				$('.klb-search-results').show();
				return false;
			}
			
			// hide search result box if click outside
			if ($(e.target).closest($('.klb-search-results')).length == 0) {
				$('.klb-search-results').hide();
			}
		}
	});
	

});