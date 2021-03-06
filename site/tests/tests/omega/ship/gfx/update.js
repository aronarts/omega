// Test mixin usage through ship
pavlov.specify("Omega.ShipGfxUpdater", function(){
describe("Omega.ShipGfxUpdater", function(){
  var ship;

  before(function(){
    ship = Omega.Gen.ship();
  });

  describe("#update_gfx", function(){
    before(function(){
      ship = new Omega.Ship({type : 'corvette', location : new Omega.Location()});
      ship.init_gfx();
    });

    it("sets position tracker position from scene location", function(){
      sinon.spy(ship.position_tracker().position, 'set');
      ship.update_gfx();
      sinon.assert.calledWith(ship.position_tracker().position.set,
                              ship.location.x,
                              ship.location.y,
                              ship.location.z);
    });

    it("sets location tracker rotation from location rotation", function(){
      var matrix = new THREE.Matrix4();
      sinon.stub(ship.location, 'rotation_matrix').returns(matrix);
      sinon.spy(ship.location_tracker().rotation, 'setFromRotationMatrix');
      ship.update_gfx();
      sinon.assert.calledWith(ship.location_tracker().rotation.setFromRotationMatrix, matrix);
    });
  });

  describe("#update_attack_gfx", function(){
    it("updates attack vector state", function(){
      ship.init_gfx();
      sinon.spy(ship.attack_vector, 'update_state');
      ship.update_attack_gfx();
      sinon.assert.called(ship.attack_vector.update_state);
    });

    it("updates attack component state", function(){
      ship.init_gfx();
      sinon.spy(ship.attack_component(), 'update_state');
      ship.update_attack_gfx();
      sinon.assert.called(ship.attack_component().update_state);
    });

    it("updates explosions state", function(){
      ship.init_gfx();
      sinon.spy(ship.explosions, 'update_state');
      ship.update_attack_gfx();
      sinon.assert.called(ship.explosions.update_state);
    });
  });

  describe("#update_defense_gfx", function(){
    it("updates hp bar", function(){
      ship.init_gfx();
      sinon.spy(ship.hp_bar, 'update');
      ship.update_defense_gfx();
      sinon.assert.called(ship.hp_bar.update);
    });

    it("updates smoke effects state", function(){
      ship.init_gfx();
      sinon.spy(ship.smoke, 'update_state');
      ship.update_defense_gfx();
      sinon.assert.called(ship.smoke.update_state);
    });
  });

  describe("#update_mining_gfx", function(){
    it("updates mining vector", function(){
      ship.init_gfx();
      sinon.spy(ship.mining_vector, 'update');
      ship.update_mining_gfx();
      sinon.assert.called(ship.mining_vector.update);
    });

    it("updates mining vector state", function(){
      ship.init_gfx();
      sinon.spy(ship.mining_vector, 'update_state');
      ship.update_mining_gfx();
      sinon.assert.called(ship.mining_vector.update_state);
    });
  });

  describe("#update_movement_effects", function(){
    describe("ship is moving linearily", function(){
      it("sets run_movement callback to run_linear_movement", function(){
        ship.location.movement_strategy =
          {json_class : 'Motel::MovementStrategies::Linear'};
        ship.update_movement_effects();
        assert(ship._run_movement).equals(ship._run_linear_movement);
      });
    });

    describe("ship is moving using follow strategy", function(){
      it("sets run_movement callback to run_follow_movement", function(){
        ship.location.movement_strategy =
          {json_class : 'Motel::MovementStrategies::Follow'};
        ship.update_movement_effects();
        assert(ship._run_movement).equals(ship._run_follow_movement);
      });
    });

    describe("ship is moving using rotate strategy", function(){
      it("sets run_movement callback to run_rotation_movement", function(){
        ship.location.movement_strategy =
          {json_class : 'Motel::MovementStrategies::Rotate'};
        ship.update_movement_effects();
        assert(ship._run_movement).equals(ship._run_rotation_movement);
      });
    });

    describe("ship is stopped", function(){
      it("sets run_movement callback to no_movement", function(){
        ship.location.movement_strategy =
          {json_class : 'Motel::MovementStrategies::Stopped'};
        ship.update_movement_effects();
        assert(ship._run_movement).equals(ship._no_movement);
      });
    });

    it("updates trails", function(){
      ship.init_gfx();
      sinon.stub(ship.trails, 'update_state');
      ship.update_movement_effects();
      sinon.assert.called(ship.trails.update_state);
    });
  });
});});
