/*jQuery(document).ready(function($) {
  function mobileCustomSearch() {
    var searchButton = $('.site-header .header-buttons .header-search-icon > a');
    var searchHolder = $('.header-search');

    console.log('Hice click en el buscador');

    searchButton.on('click', function(e) {
      e.preventDefault();
      $(this).toggleClass('active');
      searchHolder.toggleClass('active');
    });
  }

  mobileCustomSearch();
});*/


(function($) {
    
  $(document).ready(function() {
    $('.header-search-icon').on('click', function(e) {
      e.preventDefault();
      $('.header-search').toggleClass('active');
    });
  });
  
  
  $(document).ready(function() {
    var isCheckoutPage = window.location.pathname.includes('/caja/');
    if(isCheckoutPage){
    $('#billing_sucursal').on('blur', function() {
        var sucursalValue = $(this).val();
        
        if (!sucursalValue) {
            $('button#place_order.button.alt').prop('disabled', true);
            Swal.fire(
                'Oops',
                'Debe seleccionar una sucursal para proceder a la compra',
                'warning'
            );
        } else {
            $('button#place_order.button.alt').prop('disabled', false);
        }
    });
    
    $('button#place_order.button.alt').on('click', function(event) {
        if ($(this).prop('disabled')) {
            event.preventDefault(); // Evitar que el botón realice su acción por defecto
            Swal.fire(
                'Oops',
                'Debe seleccionar una sucursal para proceder a la compra',
                'warning'
            );
        }
    });
    
    
    
document.addEventListener('DOMContentLoaded', function () {
    var billingNroDoc = document.getElementById('billing_nro_doc');
    var billingTipoDoc = document.getElementsByName('billing_tipo_doc');

    billingNroDoc.addEventListener('input', function () {
        var tipoDoc = getSelectedTipoDoc();
        var formattedValue = formatBillingNroDoc(this.value, tipoDoc);
        this.value = formattedValue;
    });

    function getSelectedTipoDoc() {
        for (var i = 0; i < billingTipoDoc.length; i++) {
            if (billingTipoDoc[i].checked) {
                return billingTipoDoc[i].value;
            }
        }
        return null;
    }

    function formatBillingNroDoc(value, tipoDoc) {
        // Elimina todos los caracteres no deseados según el tipo de documento
        if (tipoDoc === '2') {
            // Si es RUC, permite solo números y un guion al final
            return value.replace(/[^\d-]/g, '').replace(/(\d)-$/g, '$1');
        } else {
            // Si es Cédula de Identidad, permite solo números
            return value.replace(/[^\d]/g, '');
        }
    }
});
    }
});

  
jQuery(document).ready(function($) {
    var slideIndex = 0;
    var slides = $('.slider').find('.slide');
    var totalSlides = slides.length;
    var isPaused = false;

    function showSlide(index) {
        if (index < 0) {
            slideIndex = totalSlides - 1;
        } else if (index >= totalSlides) {
            slideIndex = 0;
        }

        slides.hide();
        slides.eq(slideIndex).fadeIn();
    }

    $('.prev-slide').click(function() {
        slideIndex--;
        showSlide(slideIndex);
    });

    $('.next-slide').click(function() {
        slideIndex++;
        showSlide(slideIndex);
    });

    function autoSlide() {
        if (!isPaused) {
            slideIndex++;
            showSlide(slideIndex);
        }
    }

    // Deslizamiento automático cada 5 segundos
    setInterval(autoSlide, 5000);

    // Mostrar el primer slide al cargar la página
    showSlide(slideIndex);

    // Pausar slider cuando el mouse está encima de una imagen
    $('.slide').hover(
        function() {
            isPaused = true;
        },
        function() {
            isPaused = false;
        }
    );
});  
  
  
  
$(document).ready(function () {
    // Verifica si la URL contiene la palabra "caja"
    if (window.location.href.indexOf('caja') !== -1) {
        var billingNroDoc = $('#billing_nro_doc');
        var billingTipoDoc = $('input[name="billing_tipo_doc"]');
        billingNroDoc.attr('maxlength','7');
        billingTipoDoc.on('change', function () {
            var tipoDocumento = getSelectedTipoDoc();
            // Verifica el formato correcto según el tipo de documento
            if (tipoDocumento == 1) {
                // Cédula de Identidad
                billingNroDoc.attr('maxlength','7');
            } else if (tipoDocumento == 2) {
                // RUC
                billingNroDoc.attr('maxlength','8');
            }
        });
        billingNroDoc.on('input', function () {
            var tipoDoc = getSelectedTipoDoc();
            console.log('Tipo de Documento Seleccionado: ' + tipoDoc);
            var sanitizedValue = sanitizeBillingNroDoc(this.value, tipoDoc);

            this.value = sanitizedValue;
        });

        function getSelectedTipoDoc() {
            for (var i = 0; i < billingTipoDoc.length; i++) {
                if (billingTipoDoc.eq(i).prop('checked')) {
                    return billingTipoDoc.eq(i).val();
                }
            }
            return null;
        }

function sanitizeBillingNroDoc(value, tipoDoc) {
    if (tipoDoc == 2) {
        // Si es RUC, permite solo números y un guion opcional al final
        console.log('Nuevo4 Formato RUC: 1234567-8');
        //return value.replace(/[^\d-]/g, '').replace(/(\d)-?$/g, '$1');
        //return value.replace(/[^\d-]/g, '').replace(/(\d{7})-?(\d{1})?$/, '$1-$2');
        return value.replace(/[^\d-]/g, '').replace(/(\d{7})-?(\d)?(\d*)$/, function(match, p1, p2, p3) {
            // Limitar la entrada de números adicionales después del primer carácter numérico posterior al guion
            return p1 + (p2 ? '-' + p2 : '') + (p3 ? '-' + p3.slice(0, 1) : '');
        });

    } else {
        console.log('Formato CI: 1234567');
        // Si es Cédula de Identidad, permite solo números
        return value.replace(/[^\d]/g, '');
    }
}


        function validateInput(value, tipoDoc) {
            // Verifica el formato correcto según el tipo de documento
            if (tipoDoc == 1) {
                // Cédula de Identidad
                if (!/^\d{7}$/.test(value)) {
                    console.log('Caracter no permitido. Formato CI: 1234567');
                    return 'Caracter no permitido. Formato CI: 1234567';
                }
            } else if (tipoDoc == 2) {
                // RUC
                if (!/^\d{7}(-\d)?$/.test(value)) {
                    console.log('Caracter no permitido. Formato RUC: 1234567-8');
                    return 'Caracter no permitido. Formato RUC: 1234567-8';
                }
            }

            return null; // No hay error
        }
    }
}); 
  
})(jQuery);

/*(function($) {
  // Tu código jQuery aquí, ahora puedes utilizar "$" como alias de jQuery
  $(document).ready(function() {
    // Verificar si la página actual es la de "caja"
    var isCheckoutPage = window.location.pathname.includes('/caja/');

    // Obtener la nueva ubicación de la URL actual (puede ser undefined si no hay parámetro 'location')
    var newLocation = getParameterByName('location');

    // Obtener la ubicación actual de la cookie
    var currentLocation = readCookie('woocommerce_multi_inventory_location');
    var currentSucursal = readCookie('sucursal_seleccionada');

    // Si la página no es la de "caja" y hay una nueva ubicación diferente de la actual, guardarla en la cookie
    if (!isCheckoutPage && newLocation && newLocation !== currentLocation) {
        saveCookie('woocommerce_multi_inventory_location', newLocation, 365);
        saveCookie('sucursal_seleccionada', newLocation, 365);
        currentLocation = newLocation; // Actualizar el valor actual de la ubicación
        console.log('Guardando la nueva sucursal en la cookie: ' + currentLocation);
    }

    // Si la página es la de "caja" y no tiene el parámetro 'location', agregarlo de manera obligatoria
    if (isCheckoutPage && !newLocation) {
        console.log('La pagina de Caja no tiene el Parametro:' + newLocation + ' - Sucursal Seleccionada: ' + currentSucursal + ' - CurrentLocation: ' + currentLocation);
        saveCookie('woocommerce_multi_inventory_location', currentSucursal, 365);
        var checkoutURL = window.location.href;
        checkoutURL += (checkoutURL.indexOf('?') !== -1 ? "&location=" : "?location=") + currentSucursal;
        window.history.replaceState({}, '', checkoutURL);
    }
    else if (!newLocation) {
        var pageURL = window.location.href;
        pageURL += (pageURL.indexOf('?') !== -1 ? "&location=" : "?location=") + currentSucursal;
        window.history.replaceState({}, '', pageURL);
    }

    // Modificar los enlaces con la nueva ubicación
    $("a:not([href^='#'])").attr('href', function(i, h) {
        // Verificar si ya existe un parámetro 'location' en el enlace
        var locationParamIndex = h.indexOf('?location=');
        if (locationParamIndex !== -1) {
            var existingLocation = h.substring(locationParamIndex + 10); // 10 es la longitud de '?location='
            if (existingLocation !== currentSucursal) {
                // Reemplazar la ubicación anterior con la nueva
                return h.substring(0, locationParamIndex) + '?location=' + currentSucursal;
            }
        } else {
            // Agregar el parámetro 'location' al enlace
            return h + (h.indexOf('?') !== -1 ? "&location=" + currentSucursal : "?location=" + currentSucursal);
        }

        // Si el enlace ya tiene el parámetro 'location' con la ubicación actual, no hacer cambios
        return h;
    });

    function getParameterByName(name) {
        var url = window.location.href;
        name = name.replace(/[\[\]]/g, "\\$&");
        var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
            results = regex.exec(url);
        if (!results) return null;
        if (!results[2]) return '';
        return decodeURIComponent(results[2].replace(/\+/g, " "));
    }

    function readCookie(name) {
        var result = document.cookie.match(new RegExp(name + '=([^;]+)'));
        result && (result = JSON.parse(result[1]));
        return result;
    }

    function saveCookie(name, value, days) {
        var expires = "";
        if (days) {
            var date = new Date();
            date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
            expires = "; expires=" + date.toGMTString();
        }

        var cookie = name + '=' + JSON.stringify(value) + expires + '; path=/;';
        document.cookie = cookie;
    }
});

})(jQuery);
*/


jQuery(document).ready(function($) {
    $('p#sucursal_field.form-row.form-row-wide span.select2.select2-container.select2-container--default').removeAttr('style');
    
});


// Esta función verifica la resolución y mueve el elemento según sea necesario.
function checkResolution() {
    if (window.matchMedia("(max-width: 767px)").matches) {
        // Si la resolución es de móvil, mueve el elemento a '.t-Header-nav'
        console.log('Mobile, removiendo clase del desktop-containter...');
        $('#mobile-container').addClass($('slider-container'));
        $('#desktop-container').removeClass($('slider-container'));
        
        document.getElementById("mobile-container").classList.add("slider-container");
        document.getElementById("desktop-container").classList.remove("slider-container");
    } else {
        // Si la resolución es de escritorio, mueve el elemento antes de '.t-Header-navBar'
        console.log('Desktop, removiendo clase del mobile-containter...');
        $('#mobile-container').removeClass($('slider-container'));
        $('#desktop-container').addClass($('slider-container'));
        
        document.getElementById("mobile-container").classList.remove("slider-container");
        document.getElementById("desktop-container").classList.add("slider-container");
    }
}

// Ejecutar al cargar la página
//jQuery(document).ready(checkResolution());

// Añade un listener para el evento 'resize'
//jQuery(window).resize(checkResolution);


