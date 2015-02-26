# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

window.busyImage = $('#upload-modal .modal-body').html()

$(document).ready ->
  $('#upload').click ->
    $('#upload-dialog')[0].toggle()

$(document).ajaxSend (e, xhr, options) ->
  options.data = {} if !options.data?

  options.data['authenticity_token'] = $('meta[name="csrf-token"]').attr('content')
