pavlov.specify("Omega.UI.CommandTracker", function(){
describe("Omega.UI.CommandTracker", function(){
  describe("callbacks", function(){
    describe("#attacked", function(){
      var page, tracker;
      var tgt, etgt, ship, eship, eargs;

      before(function(){
        page = new Omega.Pages.Test({canvas : Omega.Test.Canvas()});
        sinon.stub(page.canvas, 'reload');

        var system = new Omega.SolarSystem({id : 'system1'});
        page.canvas.set_scene_root(system);

        tracker = new Omega.UI.CommandTracker({page : page});

        tgt    = Omega.Gen.ship({id : 'target_ship' });
        etgt   = Omega.Gen.ship({id : 'target_ship' });
        ship   = Omega.Gen.ship({id: 'ship1', system_id : 'system1'});
        eship  = Omega.Gen.ship({id: 'ship1', attacking : etgt});

        page.entities = [ship, tgt];
        eargs         = ['attacked', eship, etgt];
      });

      after(function(){
        page.canvas.reload.restore();
      });

      it("updates entity attacking target", function(){
        tracker._callbacks_attacked("manufactured::event_occurred", eargs);
        assert(ship.attacking).equals(tgt);
      });

      describe("entity not in scene", function(){
        it("does not reload entity", function(){
          ship.parent_id = 'system2';
          tracker._callbacks_attacked("manufactured::event_occurred", eargs);
          sinon.assert.notCalled(page.canvas.reload);
        });
      });

      it("reloads entity in scene", function(){
        tracker._callbacks_attacked("manufactured::event_occurred", eargs);
        sinon.assert.calledWith(page.canvas.reload, ship, sinon.match.func);
      });

      it("updates entity gfx", function(){
        sinon.stub(ship, 'update_gfx');
        tracker._callbacks_attacked("manufactured::event_occurred", eargs);
        page.canvas.reload.omega_callback()();
        sinon.assert.called(ship.update_gfx);
      });
    });
  });
});});