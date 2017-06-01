import Ember from 'ember';

export default Ember.Route.extend({
  model(params) {
    return Ember.$.get('http://localhost:4567/api/workspaces/' + params.workspace_id);
  },
});
