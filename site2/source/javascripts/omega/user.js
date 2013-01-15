/* Omega User Operations
 *
 * Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

require('javascripts/vendor/jquery.cookie.js');
require('javascripts/omega/client.js');
require('javascripts/omega/entity.js');
require('javascripts/omega/commands.js');

/////////////////////////////////////// Omega User

function OmegaUser(args){
  /////////////////////////////////////// public data

  // copy all attributes from entity to self
  // XXX needed here since OmegaUser doesn't derive from OmegaEntity
  for(var attr in args)
    this[attr] = args[attr];

  /////////////////////////////////////// public methods

  this.toJSON = function(){
    return new JRObject("Users::User", this,
      ["alliances", "toJSON", "json_class"]).toJSON();
  };
}

/////////////////////////////////////// Omega Session

/* Initialize new Omega Session
 */
function OmegaSession(){

  /////////////////////////////////////// private data

  // invoked when session validation is successful (eg page refresh when user is logged in)
  var session_validated_callbacks = [];

  // invoked when session validation is not succesful
  var invalid_session_callbacks   = [];

  // invoked when session is destroyed
  var session_destroyed_callbacks = [];

  /////////////////////////////////////// private methods

  /* Initialize the user session
   */
  var create_session = function(session_id, user_id){
    // set session id on rjr nodes
    $omega_node.set_header('session_id', session_id)
    $omega_node.set_header('source_node', user_id);

    // set session cookies
    $.cookie('omega-session', session_id);
    $.cookie('omega-user',    user_id);

    $user_id = user_id;
  };

  /* Destroy the user session
   */
  var destroy_session = function(){
    // delete session cookies
    $.cookie('omega-session', null);
    $.cookie('omega-user',    null);
  };

  /* Callback invoked to verify user session
   */
  var callback_validate_session = function(user, error){
    var ret = true;
    if(error){
      destroy_session();
      ret = false;
      for(var i = 0; i < invalid_session_callbacks.length; i++){
        invalid_session_callbacks[i]();
      }
    }else{
      $omega_registry.add(user);
      for(var i = 0; i < session_validated_callbacks.length; i++){
        session_validated_callbacks[i]();
      }
    }
    return ret;
  };

  /* Callback invoked on user login
   */
  var on_user_login = function(session){
    create_session(session.id, session.user.id);
    for(var i = 0; i < session_validated_callbacks.length; i++){
      session_validated_callbacks[i]();
    }
  };

  /* Callback invoked on login error
   */
  var on_login_error = function(error){
    destroy_session();
  }

  /* Callback invoked on user logout
   */
  var on_user_logout = function(result, error){
    destroy_session();
    for(var i = 0; i < session_destroyed_callbacks.length; i++){
      session_destroyed_callbacks[i]();
    }
  }

  /////////////////////////////////////// public methods

  this.on_session_validated = function(callback){
    session_validated_callbacks.push(callback);
  }

  /* Register function to be invoked when invalid session
   * is detected.
   */
  this.on_invalid_session = function(callback){
    invalid_session_callbacks.push(callback);
  }

  /* Register function to be invoked when session
   * is destroyed.
   */
  this.on_session_destroyed = function(callback){
    session_destroyed_callbacks.push(callback);
  }

  /* Login the user
   */
  this.login_user = function(user){
    OmegaCommand.login_user.exec(user, on_user_login, on_login_error);
  };

  /* Logout the user
   */
  this.logout_user = function(){
    var session_id = $.cookie('omega-session');
    OmegaCommand.logout_user.exec(session_id, on_user_logout);
  };

  /* Register the user
   */
  this.register_user = function(user, callback){
    $omega_node.web_request('users::register', user, callback);
  };

  /////////////////////////////////////// initialization

  // restore the session from cookies
  var user_id    = $.cookie('omega-user');
  var session_id = $.cookie('omega-session');
  if(user_id != null && session_id != null){
    create_session(session_id, user_id);
  }

  // validate the session
  if(user_id != null){
    // XXX hack, give socket time to open before running client
    setTimeout(function(){ OmegaQuery.user_with_id(user_id, callback_validate_session) },
               1000);
  }
}
