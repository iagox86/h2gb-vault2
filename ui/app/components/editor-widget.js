import Ember from 'ember';

export default Ember.Component.extend({
  action: '',
  actions: {
    changeAction: function(self) {
      this.set('action', self.target.value);
    },
    go_basic_type: function() {
      var address = document.getElementById('editor_address').value;
      var type = document.getElementById('define_basic_type_type').value;
      var request = {
        updates: [
          {
            'action': 'define_basic_type',
            'address': parseInt(address),
            'type': type,
          }
        ]
      };

      Ember.$.ajax('http://localhost:4567/api/memories/' + this.get('memory_id') + '/update', {
        data: JSON.stringify(request),
        contentType: 'application/json',
        type: 'POST',
      }).then(function() {
        window.location.reload();
      });
    },
  }
});
