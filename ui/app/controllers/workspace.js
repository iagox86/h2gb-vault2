import Ember from 'ember';

export default Ember.Controller.extend({
  actions: {
    undo: function(workspace_id) {
      Ember.$.ajax('http://localhost:4567/api/workspaces/' + workspace_id + '/undo', {
        data: JSON.stringify({}),
        contentType: 'application/json',
        type: 'POST',
      }).then(function() {
        window.location.reload();
      });
    },

    redo: function(workspace_id) {
      Ember.$.ajax('http://localhost:4567/api/workspaces/' + workspace_id + '/redo', {
        data: JSON.stringify({}),
        contentType: 'application/json',
        type: 'POST',
      }).then(function() {
        window.location.reload();
      });
    },
  },
});
