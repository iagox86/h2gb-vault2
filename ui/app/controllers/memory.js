import Ember from 'ember';

export default Ember.Controller.extend({
  actions: {
    undo: function(memory_id) {
      Ember.$.ajax('http://localhost:4567/api/memories/' + memory_id + '/undo', {
        data: JSON.stringify({}),
        contentType: 'application/json',
        type: 'POST',
      }).then(function() {
        window.location.reload();
      });
    },

    redo: function(memory_id) {
      Ember.$.ajax('http://localhost:4567/api/memories/' + memory_id + '/redo', {
        data: JSON.stringify({}),
        contentType: 'application/json',
        type: 'POST',
      }).then(function() {
        window.location.reload();
      });
    },
  },
});
