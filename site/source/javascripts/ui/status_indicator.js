/* Omega JS Status Indicator UI Component
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.StatusIndicator = function(parameters){
  /// stack of states which are currently set
  this.states =  [];
}

Omega.UI.StatusIndicator.prototype = {
  div_id    : '#status_icon',

  /// return dom component
  component : function(){
    return $(this.div_id);
  },

  /// set the status indicator background
  background : function(new_bg){
    if(new_bg == null){
      this.component().css('background', '');
      return;
    }

/// FIXME host/prefix from where?
    var url = '/images/status/' + new_bg + '.png';
    this.component().css('background', 'url("' + url + '") no-repeat');
  },

  /// return bool indicating if state is on stack
  has_state : function(state){
    for(var s = 0; s < this.states.length; s++)
      if(this.states[s] == state)
        return true;
    return false;
  },

  /// Return bool indicating if topmost state on stack is the specified state
  is_state : function(state){
    if(this.states.length == 0) return false;
    return this.states[this.states.length-1] == state;
  },

  /// Push a new state onto the stack
  push_state : function(state){
    this.states.push(state);
    this.background(state);
  },

  /// Pop a new state of the stack
  pop_state : function(){
    this.states.pop();
    if(this.states.length > 0)
      this.background(this.states[this.states.length-1])
    else
      this.background(null)
  },

  /// Follow node, push/pop specified state off stack upon node activity
  follow_node : function(node, state){
    var _this = this;
    node.addEventListener('request', function(request){
      _this.push_state(state);
    });

    node.addEventListener('msg_received', function(response){
      /// only pop for results (not notification msgs)
      if(response.id){
        _this.pop_state();
      }
    });
  },

  /// Animation method periodically invoked
  animate : function(){
    /// get bg
    var current_bg = this.component().css('background-image');

    /// if bg is set, store it and then clear it
    if(current_bg != '' && current_bg != 'none'){
      this.original_bg = current_bg;
      current_bg = '';

    /// if not set, restore it
    }else
      current_bg = this.original_bg;

    /// set bg
    this.component().css('background', current_bg);
  }
}
