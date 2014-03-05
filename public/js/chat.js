
var user_name = null;
var chat_room = null;
var ws = null;

var strip_tags = function(data) {
  return data.replace(/<(?:.|\n)*?>/gm, '');
}

var clean_chat_room = function(data) {
  data = strip_tags(data);
  return data.replace(/[^\w]/g, '');
}

var clean_user_name = function(data) {
  data = strip_tags(data);
  return data.replace(/[^\w\ ]/g, '');
}

var init_enter_chat_room_form = function(){
  $('#enter_chat_room').submit(function(){

    $form = $(this);
    $chat_room_field = $('#chat_room', $form);
    $user_name_field = $('#user_name', $form);
    chat_room = $chat_room_field.val();
    user_name = $user_name_field.val();

    // clean data
    chat_room = clean_chat_room(chat_room);
    user_name = clean_user_name(user_name);

    // update field vals
    $chat_room_field.val( chat_room );
    $user_name_field.val( user_name );

    // validate
    if (chat_room == '') {
      alert('Chat room is required.');
      return false;
    }
    if (user_name == '') {
      alert('Name is required.');
      return false;
    }

    // hide chat/user form, show message form
    $form.hide();
    init_chat_session();

    return false;

  });
}

var init_send_message_form = function(){

  // show message form
  $('#send_message').show();

  $('#chat_room_ro', $('#send_message')).val( chat_room );

  // submit handler
  $('#send_message').submit(function(){

    $form = $(this);
    $message_field = $('#message', $form);
    message = $message_field.val();

    // clean data
    message = strip_tags(message);

    // update field vals
    $message_field.val( message );

    // validate
    if (message == '') {
      alert('Message is required.');
      return false;
    }

    data = {
      user_name: user_name,
      chat_room: chat_room,
      message: message
    }

    // send message
    try {
      ws.send( JSON.stringify(data) );
    }
    catch(err) {
      // debug
      //console.debug(err);
    }

    return false;
  });

};

var init_chat_session = function(){

  // open web socket
  ws = new WebSocket("ws://127.0.0.1:8080/" + chat_room);

  ws.onerror = function(error){};

  ws.onclose = function(){};

  ws.onopen = function(){
    init_send_message_form();
  };

  ws.onmessage = function (e) {

    data = JSON.parse(e.data);
    new_message = "<dt>"+data.user_name+"</dt><dd>"+data.message+"</dd>";
    $('#chat_messages').append( new_message );

  };

}

$(document).ready(function(){

  init_enter_chat_room_form();

});
