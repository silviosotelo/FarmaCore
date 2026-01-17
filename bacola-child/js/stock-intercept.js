jQuery(function($){
  // Ensure erp_code is available (localized ft_params.erp_code in PHP)
  var erpCode = window.ft_params && ft_params.erp_code;

  // Remove Bacola's default click handler
  $(document).off('click', 'a.ajax_add_to_cart');

  // Bind new click handler with stock check
  $(document).on('click', 'a.ajax_add_to_cart', function(e){
    // Prevent default behavior and other handlers
    e.preventDefault();
    e.stopImmediatePropagation();

    var $btn      = $(this),
        productId = $btn.data('product_id'),
        qty       = $btn.data('quantity') || 1,
        sku       = $btn.data('sku') || '';

    // Remove any existing Bacola notices immediately
    $('.klb-notice-ajax').empty().hide();
    $('.woocommerce-message, .woocommerce-error').remove();

    // Build stock-check payload
    var payload = {
      STK_SUCURSAL: erpCode,
      STK_DETALLE: [{
        STK_NRO_ITEM:   1,
        STK_ARTICULO:   sku,
        STK_CANTIDAD:   qty,
        STK_PORC_DCTO:  0,
        STK_COD_PROMO:  0
      }]
    };

    // 1) Verify stock via API
    $.ajax({
      url: 'https://api.desarrollo.farmatotal.com.py/farma/next/ecommerce/producto/stock',
      method: 'POST',
      contentType: 'application/json',
      dataType: 'json',
      data: JSON.stringify(payload)
    })
    .done(function(resp){
      var item = (resp.value && resp.value[0]) || {};
      // 2a) If out of stock: show toast and exit
      if (item.stk_cant_act < qty) {
        Swal.fire({
          toast: true,
          position: 'top-end',
          icon: 'warning',
          title: 'Lo sentimos, sólo quedan ' + (item.stk_cant_act || 0) + ' unidades.',
          showConfirmButton: false,
          timer: 3000,
          timerProgressBar: true,
          didOpen: function(toast) {
            toast.addEventListener('mouseenter', Swal.stopTimer);
            toast.addEventListener('mouseleave', Swal.resumeTimer);
          }
        });
        return false;  // stop any further processing
      }

      // 2b) Stock is ok: proceed with Bacola AJAX add-to-cart
      var formData = new FormData();
      formData.append('add-to-cart', productId);
      $(document.body).trigger('adding_to_cart', [$btn, formData]);

      $.ajax({
        url: wc_add_to_cart_params.wc_ajax_url.replace('%%endpoint%%','bacola_add_to_cart_archive'),
        data: formData,
        type: 'POST',
        processData: false,
        contentType: false,
        dataType: 'json'
      })
      .done(function(response) {
        // Inject only Bacola's success notice
        var html = response.fragments.notices_html || '';
        // Remove any error notices if present
        html = html.replace(/<ul class="woocommerce-error"[\s\S]*?<\/ul>/, '');
        $(html)
          .appendTo('.klb-notice-ajax')
          .delay(3000)
          .fadeOut(300, function(){ $(this).remove(); });
      })
      .fail(function() {
        Swal.fire('Error', 'No se pudo agregar al carrito.', 'error');
      });
    })
    .fail(function() {
      Swal.fire('Error', 'No se pudo verificar el stock.', 'error');
    });
  });
});
