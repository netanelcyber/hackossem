from flask import Flask, jsonify, request, render_template_string
import functools

# ==========================================
# 1. THE "MAGIC" LINQ ENGINE (Python Side)
# ==========================================
class MagicQuery:
    """
    A tiny wrapper to enable LINQ-style chaining in Python.
    """
    def __init__(self, data):
        self.data = data

    def where(self, predicate):
        """Filters data based on a condition."""
        self.data = filter(predicate, self.data)
        return self

    def select(self, selector):
        """Projects each element into a new form."""
        self.data = map(selector, self.data)
        return self

    def order_by(self, key_selector, reverse=False):
        """Sorts the elements."""
        self.data = sorted(self.data, key=key_selector, reverse=reverse)
        return self

    def to_list(self):
        """Executes the query and returns a list."""
        return list(self.data)

# ==========================================
# 2. MOCK DATA LAYER
# ==========================================
users_db = [
    {"id": 1, "name": "Alice Wonderland", "role": "Admin", "score": 88},
    {"id": 2, "name": "Bob Builder", "role": "User", "score": 45},
    {"id": 3, "name": "Charlie Chocolate", "role": "User", "score": 92},
    {"id": 4, "name": "Dave Diver", "role": "Admin", "score": 75},
    {"id": 5, "name": "Eve Eagle", "role": "User", "score": 60},
]

# ==========================================
# 3. FLASK BACKEND
# ==========================================
app = Flask(__name__)

@app.route('/api/query', methods=['POST'])
def magic_query():
    """
    Endpoint that accepts criteria and uses our MagicQuery LINQ engine.
    """
    payload = request.json or {}
    min_score = payload.get('min_score', 0)
    role_filter = payload.get('role', None)

    # --- THE MAGIC LINQ SYNTAX ---
    # This looks just like C# LINQ but runs in Python
    query = MagicQuery(users_db) \
        .where(lambda u: u['score'] >= min_score)

    if role_filter:
        query.where(lambda u: u['role'] == role_filter)
        
    result = query \
        .order_by(lambda u: u['score'], reverse=True) \
        .select(lambda u: {
            "display_name": u['name'].upper(), 
            "details": f"{u['role']} - {u['score']} pts"
        }) \
        .to_list()
    # -----------------------------

    return jsonify(result)

# ==========================================
# 4. ANGULARJS FRONTEND (Embedded)
# ==========================================
HTML_TEMPLATE = """
<!DOCTYPE html>
<html ng-app="MagicApp">
<head>
    <title>Magic Python + Angular LINQ</title>
    <script src="https://ajax.googleapis.com/ajax/libs/angularjs/1.8.2/angular.min.js"></script>
    <style>
        body { font-family: sans-serif; background: #222; color: #fff; padding: 2rem; }
        .card { background: #333; padding: 1rem; margin-bottom: 0.5rem; border-left: 5px solid #00d8ff; }
        input, select { padding: 8px; border-radius: 4px; border: none; }
        button { background: #00d8ff; border: none; padding: 8px 16px; cursor: pointer; font-weight: bold; }
        h1 { color: #00d8ff; }
    </style>
</head>
<body ng-controller="MainCtrl as ctrl">

    <h1>⚡ Magic LINQ Dashboard</h1>
    
    <div style="margin-bottom: 20px;">
        <label>Min Score:</label>
        <input type="number" ng-model="ctrl.filters.min_score" placeholder="0">
        
        <label>Role:</label>
        <select ng-model="ctrl.filters.role">
            <option value="">All</option>
            <option value="Admin">Admin</option>
            <option value="User">User</option>
        </select>

        <button ng-click="ctrl.refreshData()">Run Magic Query</button>
    </div>

    <div ng-repeat="item in ctrl.items" class="card">
        <h3>{{ item.display_name }}</h3>
        <p>{{ item.details }}</p>
    </div>
    
    <div ng-if="ctrl.items.length === 0">No magic results found.</div>

    <script>
        var app = angular.module('MagicApp', []);

        // --- 1. MAGIC SERVICE (Dependency Injection) ---
        app.service('MagicDataService', ['$http', function($http) {
            this.query = function(filters) {
                // "Injecting" the query parameters into the backend
                return $http.post('/api/query', filters);
            };
        }]);

        // --- 2. CONTROLLER ---
        app.controller('MainCtrl', ['MagicDataService', function(MagicDataService) {
            var vm = this;
            
            vm.filters = { min_score: 50, role: '' };
            vm.items = [];

            vm.refreshData = function() {
                console.log("Injecting Query...", vm.filters);
                
                MagicDataService.query(vm.filters)
                    .then(function(response) {
                        vm.items = response.data;
                    }, function(error) {
                        console.error("Magic smoke escaped!", error);
                    });
            };

            // Initial load
            vm.refreshData();
        }]);
    </script>
</body>
</html>
"""

@app.route('/')
def index():
    return render_template_string(HTML_TEMPLATE)

if __name__ == '__main__':
    print("✨ Magic Server running at http://localhost:5000")
    app.run(debug=True, port=5000)
