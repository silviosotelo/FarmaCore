jQuery(function($){
  // Función que llama a tu API y devuelve un Promise
  function checkStock(sku, qty) {
    console.log('→ checkStock: llamando a la API con', { sku, qty, erp: ft_params.erp_code });
    return $.ajax({
      url: 'https://api.desarrollo.farmatotal.com.py/farma/next/ecommerce/stock',
      method: 'POST',
      contentType: 'application/json',
      dataType: 'json',
      data: JSON.stringify({
        STK_SUCURSAL: ft_params.erp_code,
        STK_DETALLE: [{
          STK_NRO_ITEM:   1,
          STK_ARTICULO:   sku,
          STK_CANTIDAD:   qty,
          STK_PORC_DCTO:  0,
          STK_COD_PROMO:  0
        }]
      })
    })
    .done(function(resp){
      console.log('← API respondió OK:', resp);
    })
    .fail(function(jqXHR, textStatus, errorThrown){
      console.log('← API devolvió ERROR:', textStatus, errorThrown, jqXHR.responseText);
    });
  }

  // Intercepta el botón de add-to-cart en el loop (archive)
  $(document).on('click', 'a.ajax_add_to_cart', function(e){
    e.preventDefault();
    var $btn      = $(this),
        productId = $btn.data('product_id'),
        qty       = $btn.data('quantity') || 1,
        sku       = $btn.data('sku');

    console.log('Click add-to-cart:', { productId, qty, sku });

    $btn.prop('disabled', true);

    // 1) Primero la consulta de stock
    checkStock(sku, qty)
      .done(function(resp){
        var item = resp.value && resp.value[0];
        console.log('Validación de stock:', item);
        if (!item || item.stk_cant_act < qty) {
          console.warn('No hay suficiente stock, cancelando add-to-cart.');
          Swal.fire('Sin stock',
                    'No hay suficientes unidades en la sucursal seleccionada.',
                    'warning');
          $btn.prop('disabled', false);
        } else {
          console.log('Hay stock — procedo al add-to-cart de WooCommerce');
          // 2) Si hay stock, llamamos al AJAX native de WooCommerce
          $.post(
            ft_params.add_to_cart_url,
            { product_id: productId, quantity: qty }
          )
          .done(function(res){
            console.log('WooCommerce add_to_cart OK:', res);
            $( document.body ).trigger( 'added_to_cart', [ res.fragments, res.cart_hash, $btn ] );
          })
          .fail(function(xhr, status){
            console.error('Error en add_to_cart:', status, xhr);
          })
          .always(function(){
            $btn.prop('disabled', false);
          });
        }
      });
  });

  // (Opcional) Mismo patrón para single-product
  $('form.cart').on('submit', function(e){
    e.preventDefault();
    var $form     = $(this),
        productId = $form.find('button.single_add_to_cart_button').val(),
        qty       = $form.find('input.qty').val(),
        sku       = $form.find('input[name="variation_id"]').length
                    ? $form.find('input[name="variation_id"]').val()
                    : $form.data('sku') || '';

    console.log('Submit single-product cart:', { productId, qty, sku });

    // ... repetir el mismo flow checkStock() → add_to_cart()
  });
});
