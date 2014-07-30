/* Omega Ship Missiles Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/has_target"

//= require "omega/ship/attack/missile"

Omega.ShipMissiles = function(args){
  if(!args) args = {};
  var template = args['template'];

  if(template) this.template = template;
  this.missiles = [];
  this.disable_target_update();
}

Omega.ShipMissiles.prototype = {
  interval : 10,

  should_launch : function(){
    var now = new Date();
    return this.enabled && (!(this.launched_at) ||
           (now - this.launched_at) > (this.interval * 1000));
  },

  launch : function(){
    this.launched_at = new Date();
    var missile = this.template.clone();
    missile.set_source(this.omega_entity);
    missile.set_target(this.target());
    this.missiles.push(missile);

    var _this = this;
    this.omega_entity.reload_in_scene(function(){
      _this.omega_entity.components.push(missile.component());
    });
  },

  clone : function(config, event_cb){
    return new Omega.ShipMissiles({template : this.template.clone()});
  },

  target : function(){
    return this.omega_entity.attacking;
  },

  update_target_loc : function(){
    this.target_loc(this.target().scene_location());
    for(var m = 0; m < this.missiles.length; m++)
      this.missiles[m].set_target(this.target());
  },

  enable : function(){
    this.enabled = true;
  },

  disable : function(){
    this.enabled = false;
  },

  remove : function(missile){
    var _this = this;
    this.omega_entity.reload_in_scene(function(){
      var index = _this.omega_entity.components.indexOf(missile.component());
      if(index != -1) _this.omega_entity.components.splice(index, 1);
    });

    this.missiles.splice(this.missiles.indexOf(missile), 1);
  },

  run_effects : function(){
    if(this.should_launch()) this.launch();

    for(var m = 0; m < this.missiles.length; m++){
      var missile = this.missiles[m];
      if(missile.near_target()){
        missile.explode();
        this.remove(missile);
      }else{
        missile.move_to_target();
      }
    }
  }
};

/// Async template missiles loader
Omega.ShipMissiles.load_template = function(config, type, cb){
  Omega.ShipMissile.load_template(config, type, function(missile){
    var missiles = new Omega.ShipMissiles({template: missile});
    cb(missiles);
    Omega.Ship.prototype.loaded_resource('template_missiles_' + type, missiles);
  });
};

/// Async missiles loader
Omega.ShipMissiles.load = function(type, cb){
  Omega.Ship.prototype.retrieve_resource('template_missiles_' + type,
    function(template_missiles){
      var missiles = template_missiles.clone();
      cb(missiles);
    });
};

$.extend(Omega.ShipMissiles.prototype, Omega.UI.HasTarget.prototype);
