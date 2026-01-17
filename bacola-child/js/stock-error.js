jQuery(function($){
  $(document).on('ajaxError', function(event, jqXHR, settings){
    // Solo nos interesan los endpoints de add_to_cart
    if ( settings.url.indexOf('wc-ajax=add_to_cart') !== -1 ||
         settings.url.indexOf('wc-ajax=bacola_add_to_cart_archive') !== -1 ) {
      let res;
      try {
        res = JSON.parse(jqXHR.responseText);
      } catch (e) {
        return; // no es JSON válido
      }
      if ( res.success === false && res.data && res.data.message ) {
        Swal.fire({
          toast: true,
          position: 'top-end',
          icon: 'warning',
          title: res.data.message,
          showConfirmButton: false,
          timer: 3000,
          timerProgressBar: true,
          didOpen: (toast) => {
            toast.addEventListener('mouseenter', Swal.stopTimer);
            toast.addEventListener('mouseleave', Swal.resumeTimer);
          }
        });
      }
    }
  });
});
