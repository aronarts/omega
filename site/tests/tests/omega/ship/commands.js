// Test mixin usage through ship
pavlov.specify("Omega.ShipCommands", function(){
describe("Omega.ShipCommands", function(){
  var ship, page, orig_session;

  before(function(){
    ship = Omega.Gen.ship({id : 'ship1', hp : 42, user_id: 'user1'});
    ship.location.set(99, -2, 100);
    ship.resources = [{material_id : 'gold', quantity : 50},
                      {material_id : 'ruby', quantity : 25}];

    page = Omega.Test.Page();
    orig_session = page.session;
    page.session = new Omega.Session({user_id : 'user1'});
  });

  after(function(){
    page.session = orig_session;
  });

  describe("#retrieve_details", function(){
    var details_cb;

    before(function(){
      details_cb = sinon.spy();
    });

    it("invokes details cb with ship properties", function(){
      var text = ['Ship: ship1<br/>',
                  '@ 99/-2/100<br/>',
                  '> 0/0/1<br/>',
                  'HP: 42<br/>',
                  'Type: corvette<br/>',
                  'Resources:<br/>',
                  '50 of gold<br/>',
                  '25 of ruby<br/>'];

      ship.retrieve_details(page, details_cb);
      sinon.assert.called(details_cb);

      var details = details_cb.getCall(0).args[0];
      assert(details[0]).equals(text[0]);
      assert(details[1]).equals(text[1]);
      assert(details[2]).equals(text[2]);
      assert(details[3]).equals(text[3]);
      assert(details[4]).equals(text[4]);
      assert(details[5]).equals(text[5]);
      assert(details[6]).equals(text[6]);
    });

    it("invokes details with commands", function(){
      ship.retrieve_details(page, details_cb);
      var details = details_cb.getCall(0).args[0];
      assert(details[8].html()).equals('follow');

      for(var c = 0; c < Omega.Ship.prototype.cmds.length; c++){
        var cmd = Omega.Ship.prototype.cmds[c];
        var detail_cmd = details[9+c];
        assert(detail_cmd[0].id).equals(cmd.id + ship.id);
        assert(detail_cmd[0].className).equals(cmd.class);
        assert(detail_cmd.html()).equals(cmd.text);
      }
    });

    describe("ship does not belong to user", function(){
      it("does not invoke details with commands", function(){
        ship.user_id = 'user2';
        ship.retrieve_details(page, details_cb);
        var details = details_cb.getCall(0).args[0];
        assert(details.length).equals(9);
      });
    });

    it("hides commands 'display' returns false for", function(){
      ship.retrieve_details(page, details_cb);
      var details = details_cb.getCall(0).args[0];
      for(var c = 0; c < Omega.Ship.prototype.cmds.length; c++){
        var cmd = Omega.Ship.prototype.cmds[c];
        var detail_cmd = details[9+c];
        var display = (!cmd.display || cmd.display(ship)) ? 'block' : 'none';
        assert(detail_cmd.css('display')).equals(display);
      }
    });

    describe("ship is not docked", function(){
      before(function(){
        ship.retrieve_details(page, function(details){
          $('#qunit-fixture').append(details);
        });
      });

      it("displays dock cmd", function(){
        assert($('#ship_dock_' + ship.id)).isVisible();
      });

      it("hides undock cmd", function(){
        assert($('#ship_undock_' + ship.id)).isHidden();
      });

      it("hides transfer cmd", function(){
        assert($('#ship_transfer_' + ship.id)).isHidden();
      });
    });

    describe("ship is docked", function(){
      before(function(){
        ship.docked_at_id = 'station1';
        ship.retrieve_details(page, function(details){
          $('#qunit-fixture').append(details);
        });
      });

      it("hides dock cmd", function(){
        assert($('#ship_dock_' + ship.id)).isHidden();
      });

      it("displays undock cmd", function(){
        assert($('#ship_undock_' + ship.id)).isVisible();
      });

      it("displays transfer cmd", function(){
        assert($('#ship_transfer_' + ship.id)).isVisible();
      });
    });

    it("sets ship in all command data", function(){
      ship.retrieve_details(page, details_cb);
      var details = details_cb.getCall(0).args[0];
      for(var c = 0; c < Omega.Ship.prototype.cmds.length; c++){
        var detail_cmd = details[9+c];
        assert(detail_cmd.data('ship')).equals(ship);;
      }
    });

    it("wires up command click events", function(){
      ship.retrieve_details(page, details_cb);
      var details = details_cb.getCall(0).args[0];
      for(var c = 0; c < Omega.Ship.prototype.cmds.length; c++){
        var detail_cmd = details[9+c];
        assert(detail_cmd).handles('click');
      }
    });

    describe("on command click", function(){
      it("invokes command handler", function(){
        ship.retrieve_details(page, details_cb);
        var details = details_cb.getCall(0).args[0];

        var stubs = [], cmds = [];
        for(var c = 0; c < Omega.Ship.prototype.cmds.length; c++){
          var scmd = Omega.Ship.prototype.cmds[c];
          stubs.push(sinon.stub(ship, scmd['handler']));
          cmds.push(details[9+c]);
        }

        $('#qunit-fixture').append(cmds);
        for(var c = 0; c < cmds.length; c++)
          cmds[c].click();
        for(var s = 0; s < stubs.length; s++)
          sinon.assert.calledWith(stubs[s], page);
      });
    });

    //it("wires up follow command click event"); NIY

    //describe("on follow command click", function(){
      //it("starts following entity location with canvas camera") NIY
      //it("sets command text to 'unfollow'"); // NIY
    //});

    //describe("on unfollow", function(){
      //it("stops canvas camera following"); NIY
      //it("sets command text to 'follow'); NIY
    //});
  });
});});
