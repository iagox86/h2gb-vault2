import Ember from 'ember';

export default Ember.Controller.extend({
  actions: {
    undo: function() {
      Ember.$.ajax('http://localhost:4567/api/memories/1/undo', {
        data: JSON.stringify({}),
        contentType: 'application/json',
        type: 'POST',
      }).then(function() {
        window.location.reload();
      });
    },

    redo: function() {
      Ember.$.ajax('http://localhost:4567/api/memories/1/redo', {
        data: JSON.stringify({}),
        contentType: 'application/json',
        type: 'POST',
      }).then(function() {
        window.location.reload();
      });
    },
  },
});
