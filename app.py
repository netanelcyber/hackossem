from flask import Flask, jsonify, request, render_template_string
import os
import requests
from typing import List, Dict, Optional

# ==========================================
# 0) VulnLab AD Labs Integration
# ==========================================
class VulnLabClient:
    """Client for fetching AD labs from VulnLab platform."""

    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or os.environ.get('VULNLAB_API_KEY')
        self.base_url = "https://api.vulnlab.com"
        self.timeout = 10

    def get_ad_labs(self) -> List[Dict]:
        """Fetch all AD (Active Directory) labs from VulnLab."""
        if not self.api_key:
            return self._get_mock_ad_labs()

        try:
            headers = {
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json"
            }

            # Try to fetch from actual VulnLab API
            response = requests.get(
                f"{self.base_url}/labs?category=active-directory",
                headers=headers,
                timeout=self.timeout
            )

            if response.status_code == 200:
                data = response.json()
                return self._parse_labs(data)
            else:
                # Fallback to mock if API fails
                return self._get_mock_ad_labs()
        except Exception as e:
            # Fallback to mock on any error
            print(f"VulnLab API error: {e}")
            return self._get_mock_ad_labs()

    def _parse_labs(self, data: Dict) -> List[Dict]:
        """Parse VulnLab API response into standardized format."""
        labs = []
        items = data.get('data', []) if isinstance(data, dict) else data

        for lab in items:
            labs.append({
                'id': lab.get('id', ''),
                'name': lab.get('name', 'Unnamed Lab'),
                'description': lab.get('description', ''),
                'difficulty': lab.get('difficulty', 'Unknown'),
                'category': lab.get('category', 'active-directory'),
                'machines': lab.get('machines', []),
                'tags': lab.get('tags', []),
                'url': lab.get('url', '')
            })

        return labs

    def _get_mock_ad_labs(self) -> List[Dict]:
        """Return mock AD labs data for demonstration."""
        return [
            {
                'id': 'ad-lab-1',
                'name': 'Active Directory Basics',
                'description': 'Learn fundamental Active Directory concepts including domains, users, and groups.',
                'difficulty': 'Easy',
                'category': 'active-directory',
                'machines': ['DC-1', 'CLIENT-1'],
                'tags': ['AD', 'Windows', 'Beginner'],
                'url': 'https://vulnlab.com/labs/ad-basics'
            },
            {
                'id': 'ad-lab-2',
                'name': 'LDAP Enumeration & Exploitation',
                'description': 'Master LDAP protocol exploitation and enumeration techniques in Active Directory environments.',
                'difficulty': 'Medium',
                'category': 'active-directory',
                'machines': ['DC-1', 'CLIENT-1', 'CLIENT-2'],
                'tags': ['LDAP', 'Enumeration', 'AD', 'Exploitation'],
                'url': 'https://vulnlab.com/labs/ldap-enum'
            },
            {
                'id': 'ad-lab-3',
                'name': 'Kerberos & ASREProast',
                'description': 'Understand Kerberos authentication and perform ASREProast attacks against AD users.',
                'difficulty': 'Medium',
                'category': 'active-directory',
                'machines': ['DC-1', 'CLIENT-1'],
                'tags': ['Kerberos', 'ASREProast', 'AD', 'Attacks'],
                'url': 'https://vulnlab.com/labs/kerberos-asreproast'
            },
            {
                'id': 'ad-lab-4',
                'name': 'Privilege Escalation in AD',
                'description': 'Exploit common privilege escalation vectors in Active Directory environments.',
                'difficulty': 'Hard',
                'category': 'active-directory',
                'machines': ['DC-1', 'CLIENT-1', 'CLIENT-2', 'SERVER-1'],
                'tags': ['Privilege Escalation', 'AD', 'Post-Exploitation'],
                'url': 'https://vulnlab.com/labs/ad-privesc'
            },
            {
                'id': 'ad-lab-5',
                'name': 'Golden Ticket & Domain Takeover',
                'description': 'Learn about Golden Tickets, Pass-the-Hash attacks, and techniques for domain takeover.',
                'difficulty': 'Hard',
                'category': 'active-directory',
                'machines': ['DC-1', 'CLIENT-1', 'CLIENT-2'],
                'tags': ['Golden Ticket', 'PTH', 'Domain Control', 'AD'],
                'url': 'https://vulnlab.com/labs/golden-ticket'
            }
        ]

# ==========================================
# 1) מנוע "LINQ" קטן בפייתון
# ==========================================
class MagicQuery:
    """עטיפה קטנה שמאפשרת שרשור בסגנון LINQ."""
    def __init__(self, data):
        self.data = data

    def where(self, predicate):
        self.data = filter(predicate, self.data)
        return self

    def select(self, selector):
        self.data = map(selector, self.data)
        return self

    def order_by(self, key_selector, reverse=False):
        self.data = sorted(self.data, key=key_selector, reverse=reverse)
        return self

    def to_list(self):
        return list(self.data)


# ==========================================
# 2) שכבת נתונים לדוגמה
# ==========================================
users_db = [
    {"id": 1, "name": "Alice Wonderland", "role": "Admin", "score": 88},
    {"id": 2, "name": "Bob Builder", "role": "User", "score": 45},
    {"id": 3, "name": "Charlie Chocolate", "role": "User", "score": 92},
    {"id": 4, "name": "Dave Diver", "role": "Admin", "score": 75},
    {"id": 5, "name": "Eve Eagle", "role": "User", "score": 60},
]

app = Flask(__name__)
vulnlab_client = VulnLabClient()

# ==========================================
# 3) API: VulnLab AD Labs
# ==========================================
@app.route("/api/vulnlab/ad-labs", methods=["GET"])
def api_get_ad_labs():
    """Fetch all AD labs from VulnLab."""
    labs = vulnlab_client.get_ad_labs()

    # Use MagicQuery to allow filtering
    difficulty = request.args.get('difficulty')
    search = request.args.get('search', '').lower()

    q = MagicQuery(labs)

    if difficulty:
        q = q.where(lambda lab: lab['difficulty'].lower() == difficulty.lower())

    if search:
        q = q.where(lambda lab: search in lab['name'].lower() or search in lab['description'].lower())

    result = q.order_by(lambda lab: lab['name']).to_list()

    return jsonify({
        'total': len(result),
        'labs': result
    })


# ==========================================
# 3b) API: שאילתת LINQ בפייתון
# ==========================================
@app.route("/api/query/linq", methods=["POST"])
def api_query_linq():
    payload = request.get_json(silent=True) or {}
    min_score = int(payload.get("min_score", 0) or 0)
    role_filter = payload.get("role") or None

    q = MagicQuery(users_db).where(lambda u: u["score"] >= min_score)

    if role_filter:
        q = q.where(lambda u: u["role"] == role_filter)

    result = (
        q.order_by(lambda u: u["score"], reverse=True)
         .select(lambda u: {
             "שם_לתצוגה": u["name"].upper(),
             "פרטים": f"{u['role']} - {u['score']} נקודות"
         })
         .to_list()
    )

    return jsonify(result)


# ==========================================
# 4) WASM: קומפילציה (JIT) לקוד מכונה מקומי
#    ב־Windows x64 זה יתורגם ל x86_64 Windows
# ==========================================
try:
    from wasmer import engine, wat2wasm, Store, Module, Instance
    from wasmer_compiler_cranelift import Compiler
    WASMER_AVAILABLE = True
except Exception:
    WASMER_AVAILABLE = False


def compile_and_run_wasm(threshold: int):
    """
    יוצר WAT דינמי לפי threshold, מקמפל ל-WASM ואז JIT לקוד מכונה מקומי, ומריץ.
    (דמו - מקמפל כל בקשה מחדש)
    """
    if not WASMER_AVAILABLE:
        raise RuntimeError(
            "חסרות תלויות WASM. התקן: pip install wasmer wasmer_compiler_cranelift"
        )

    wat_code = f"""
    (module
      (func $filter (param $score i32) (result i32)
        local.get $score
        i32.const {int(threshold)}
        i32.ge_s)
      (export "filter" (func $filter)))
    """

    wasm_bytes = wat2wasm(wat_code)
    store = Store(engine.JIT(Compiler))
    module = Module(store, wasm_bytes)
    instance = Instance(module)

    return [u for u in users_db if instance.exports.filter(int(u["score"]))]


@app.route("/api/query/wasm", methods=["POST"])
def api_query_wasm():
    payload = request.get_json(silent=True) or {}
    min_score = int(payload.get("min_score", 0) or 0)

    try:
        filtered = compile_and_run_wasm(min_score)
        # מחזירים בפורמט פשוט
        return jsonify([{"name": u["name"], "score": u["score"]} for u in filtered])
    except Exception as e:
        return jsonify({"שגיאה": str(e)}), 400


# ==========================================
# 5) HTML Templates for UI
# ==========================================
VULNLAB_HTML = """{% raw %}
<!DOCTYPE html>
<html ng-app="VulnLabApp" dir="ltr" lang="en">
<head>
  <meta charset="utf-8"/>
  <title>VulnLab AD Labs</title>
  <script src="https://ajax.googleapis.com/ajax/libs/angularjs/1.8.2/angular.min.js"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      min-height: 100vh;
      padding: 2rem;
      color: #333;
    }
    .container {
      max-width: 1200px;
      margin: 0 auto;
    }
    header {
      background: white;
      padding: 2rem;
      border-radius: 8px;
      margin-bottom: 2rem;
      box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    }
    h1 {
      color: #667eea;
      margin-bottom: 0.5rem;
      font-size: 2.5rem;
    }
    .subtitle {
      color: #666;
      font-size: 1rem;
      margin-bottom: 1rem;
    }
    .controls {
      display: flex;
      gap: 1rem;
      flex-wrap: wrap;
      margin-top: 1.5rem;
    }
    input, select {
      padding: 10px 15px;
      border: 2px solid #e0e0e0;
      border-radius: 4px;
      font-size: 1rem;
      flex: 1;
      min-width: 200px;
    }
    input:focus, select:focus {
      outline: none;
      border-color: #667eea;
    }
    button {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      border: none;
      padding: 10px 25px;
      border-radius: 4px;
      cursor: pointer;
      font-weight: bold;
      font-size: 1rem;
      transition: transform 0.2s, box-shadow 0.2s;
    }
    button:hover {
      transform: translateY(-2px);
      box-shadow: 0 6px 12px rgba(102, 126, 234, 0.4);
    }
    .labs-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
      gap: 1.5rem;
      margin-top: 2rem;
    }
    .lab-card {
      background: white;
      border-radius: 8px;
      padding: 1.5rem;
      box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
      transition: transform 0.3s, box-shadow 0.3s;
      border-left: 4px solid #667eea;
    }
    .lab-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 8px 12px rgba(0, 0, 0, 0.15);
    }
    .lab-card h3 {
      color: #667eea;
      margin-bottom: 0.5rem;
      font-size: 1.3rem;
    }
    .lab-card p {
      color: #666;
      line-height: 1.5;
      margin-bottom: 1rem;
      font-size: 0.95rem;
    }
    .lab-meta {
      display: flex;
      gap: 0.5rem;
      flex-wrap: wrap;
      margin-bottom: 1rem;
    }
    .badge {
      display: inline-block;
      padding: 0.4rem 0.8rem;
      border-radius: 20px;
      font-size: 0.8rem;
      font-weight: bold;
    }
    .difficulty-easy { background: #d4edda; color: #155724; }
    .difficulty-medium { background: #fff3cd; color: #856404; }
    .difficulty-hard { background: #f8d7da; color: #721c24; }
    .tag {
      background: #e7f3ff;
      color: #004085;
    }
    .machines {
      background: #f5f5f5;
      padding: 0.8rem;
      border-radius: 4px;
      margin-bottom: 1rem;
      font-size: 0.9rem;
    }
    .machines strong { color: #667eea; }
    .machine-list {
      display: flex;
      gap: 0.5rem;
      flex-wrap: wrap;
      margin-top: 0.5rem;
    }
    .machine {
      background: white;
      border: 1px solid #ddd;
      padding: 0.3rem 0.8rem;
      border-radius: 3px;
      font-family: monospace;
      font-size: 0.85rem;
    }
    .lab-link {
      display: inline-block;
      color: #667eea;
      text-decoration: none;
      font-weight: bold;
      margin-top: 1rem;
      transition: color 0.2s;
    }
    .lab-link:hover {
      color: #764ba2;
      text-decoration: underline;
    }
    .no-results {
      background: white;
      padding: 2rem;
      border-radius: 8px;
      text-align: center;
      color: #666;
      font-size: 1.1rem;
    }
    .loading {
      text-align: center;
      color: white;
      font-size: 1.2rem;
    }
    .stats {
      background: white;
      padding: 1rem;
      border-radius: 4px;
      margin-bottom: 1rem;
      font-size: 0.95rem;
      color: #666;
    }
    nav {
      background: white;
      padding: 1rem;
      border-radius: 8px;
      margin-bottom: 2rem;
      box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    }
    nav a {
      color: #667eea;
      text-decoration: none;
      margin-right: 1.5rem;
      font-weight: bold;
      transition: color 0.2s;
    }
    nav a:hover {
      color: #764ba2;
    }
  </style>
</head>
<body ng-controller="AdLabsCtrl as ctrl">
  <div class="container">
    <nav>
      <a href="/">← Home</a>
      <a href="/linq">LINQ Demo</a>
      <a href="/wasm">WASM Demo</a>
    </nav>

    <header>
      <h1>🔐 VulnLab Active Directory Labs</h1>
      <p class="subtitle">Master AD security with hands-on penetration testing labs</p>

      <div class="controls">
        <input
          type="text"
          ng-model="ctrl.searchTerm"
          placeholder="Search labs by name or description..."
          ng-change="ctrl.filterLabs()">

        <select ng-model="ctrl.selectedDifficulty" ng-change="ctrl.filterLabs()">
          <option value="">All Difficulty Levels</option>
          <option value="Easy">Easy</option>
          <option value="Medium">Medium</option>
          <option value="Hard">Hard</option>
        </select>

        <button ng-click="ctrl.refresh()">🔄 Refresh</button>
      </div>
    </header>

    <div ng-if="ctrl.loading" class="loading">
      ⏳ Loading AD labs...
    </div>

    <div ng-if="!ctrl.loading && ctrl.displayedLabs">
      <div class="stats">
        📊 Showing {{ctrl.displayedLabs.length}} of {{ctrl.allLabs.length}} labs
      </div>

      <div ng-if="ctrl.displayedLabs.length === 0" class="no-results">
        No labs found matching your criteria. Try adjusting your filters.
      </div>

      <div class="labs-grid" ng-if="ctrl.displayedLabs.length > 0">
        <div ng-repeat="lab in ctrl.displayedLabs" class="lab-card">
          <h3>{{lab.name}}</h3>
          <p>{{lab.description}}</p>

          <div class="lab-meta">
            <span class="badge" ng-class="'difficulty-' + lab.difficulty.toLowerCase()">
              📈 {{lab.difficulty}}
            </span>
            <span ng-repeat="tag in lab.tags" class="badge tag">{{tag}}</span>
          </div>

          <div class="machines" ng-if="lab.machines && lab.machines.length > 0">
            <strong>🖥️ Machines:</strong>
            <div class="machine-list">
              <span ng-repeat="machine in lab.machines" class="machine">{{machine}}</span>
            </div>
          </div>

          <a ng-href="{{lab.url}}" target="_blank" class="lab-link" ng-if="lab.url">
            Launch Lab →
          </a>
        </div>
      </div>
    </div>
  </div>

  <script>
    angular.module('VulnLabApp', [])
      .controller('AdLabsCtrl', ['$scope', '$http', function($scope, $http) {
        var vm = this;
        vm.loading = true;
        vm.allLabs = [];
        vm.displayedLabs = [];
        vm.searchTerm = '';
        vm.selectedDifficulty = '';

        vm.refresh = function() {
          vm.loading = true;
          $http.get('/api/vulnlab/ad-labs')
            .then(function(response) {
              vm.allLabs = response.data.labs;
              vm.filterLabs();
            })
            .catch(function(error) {
              console.error('Error fetching labs:', error);
              alert('Failed to load AD labs. Please check the console.');
            })
            .finally(function() {
              vm.loading = false;
            });
        };

        vm.filterLabs = function() {
          vm.displayedLabs = vm.allLabs.filter(function(lab) {
            var matchesSearch = !vm.searchTerm ||
              lab.name.toLowerCase().includes(vm.searchTerm.toLowerCase()) ||
              lab.description.toLowerCase().includes(vm.searchTerm.toLowerCase());

            var matchesDifficulty = !vm.selectedDifficulty ||
              lab.difficulty === vm.selectedDifficulty;

            return matchesSearch && matchesDifficulty;
          });
        };

        vm.refresh();
      }]);
  </script>
</body>
</html>
{% endraw %}
"""

# ==========================================
# 6) דפי AngularJS (עברית)
# ==========================================
LINQ_HTML = """
<!DOCTYPE html>
<html ng-app="MagicApp" dir="rtl" lang="he">
<head>
  <meta charset="utf-8"/>
  <title>דמו LINQ בפייתון</title>
  <script src="https://ajax.googleapis.com/ajax/libs/angularjs/1.8.2/angular.min.js"></script>
  <style>
    body { font-family: sans-serif; background: #222; color: #fff; padding: 2rem; }
    .card { background: #333; padding: 1rem; margin-bottom: 0.5rem; border-right: 5px solid #00d8ff; }
    input, select { padding: 8px; border-radius: 4px; border: none; }
    button { background: #00d8ff; border: none; padding: 8px 16px; cursor: pointer; font-weight: bold; }
    h1 { color: #00d8ff; }
    a { color: #00d8ff; }
    label { margin-left: 8px; }
  </style>
</head>
<body ng-controller="MainCtrl as ctrl">
  <h1>⚡ דשבורד LINQ “קסום”</h1>
  <p><a href="/wasm">מעבר לדמו WASM →</a></p>

  <div style="margin-bottom: 20px;">
    <label>ציון מינימלי:</label>
    <input type="number" ng-model="ctrl.filters.min_score" placeholder="0">

    <label>תפקיד:</label>
    <select ng-model="ctrl.filters.role">
      <option value="">הכל</option>
      <option value="Admin">Admin</option>
      <option value="User">User</option>
    </select>

    <button ng-click="ctrl.refreshData()">הרץ שאילתה</button>
  </div>

  <div ng-repeat="item in ctrl.items" class="card">
    <h3>{{ item.שם_לתצוגה }}</h3>
    <p>{{ item.פרטים }}</p>
  </div>

  <div ng-if="ctrl.items.length === 0">לא נמצאו תוצאות.</div>

  <script>
    var app = angular.module('MagicApp', []);

    app.service('MagicDataService', ['$http', function($http) {
      this.query = function(filters) {
        return $http.post('/api/query/linq', filters);
      };
    }]);

    app.controller('MainCtrl', ['MagicDataService', function(MagicDataService) {
      var vm = this;
      vm.filters = { min_score: 50, role: '' };
      vm.items = [];

      vm.refreshData = function() {
        MagicDataService.query(vm.filters).then(function(res) {
          vm.items = res.data;
        }, function(err) {
          console.error(err);
          vm.items = [];
        });
      };

      vm.refreshData();
    }]);
  </script>
</body>
</html>
"""

WASM_HTML = """
<!DOCTYPE html>
<html ng-app="MagicApp" dir="rtl" lang="he">
<head>
  <meta charset="utf-8"/>
  <title>דמו WASM (JIT ל-x86_64)</title>
  <script src="https://ajax.googleapis.com/ajax/libs/angularjs/1.8.2/angular.min.js"></script>
  <style>
    body { font-family: 'Segoe UI', sans-serif; background: #121212; color: #e0e0e0; padding: 2rem; }
    .container { max-width: 700px; margin: auto; border: 1px solid #333; padding: 20px; border-radius: 8px; }
    .card { background: #1e1e1e; padding: 10px; margin: 10px 0; border-right: 4px solid #bb86fc; }
    input { background: #2c2c2c; color: white; border: 1px solid #444; padding: 10px; width: 140px; }
    button { background: #bb86fc; color: black; border: none; padding: 10px 20px; font-weight: bold; cursor: pointer; }
    .badge { color: #03dac6; font-family: monospace; }
    a { color: #bb86fc; }
    .error { color: #ff6b6b; white-space: pre-wrap; }
    code { color: #03dac6; }
  </style>
</head>
<body ng-controller="MainCtrl">
  <div class="container">
    <h1>⚡ WASM <span class="badge">JIT → x86_64</span></h1>
    <p><a href="/linq">← חזרה לדמו LINQ</a></p>

    <p>
      ב־Windows x64, הקומפילציה כאן יוצרת קוד מכונה מקומי (x86_64 Windows) בזמן ריצה.
    </p>

    <div style="margin-bottom: 20px;">
      <label>ציון >= </label>
      <input type="number" ng-model="min_score">
      <button ng-click="refresh()">הרץ קומפילציה והרצה</button>
    </div>

    <div class="error" ng-if="error">{{ error }}</div>

    <div ng-repeat="u in items" class="card">
      <strong>{{ u.name }}</strong> — ציון: {{ u.score }}
    </div>

    <p ng-if="!error && items.length == 0">אין תוצאות.</p>

    <hr style="border-color:#333"/>
    <p style="opacity:0.9">
      אם אתה רואה שגיאה על Wasmer: ודא שהתקנת<br/>
      <code>pip install wasmer wasmer_compiler_cranelift</code>
    </p>
  </div>

  <script>
    angular.module('MagicApp', [])
      .controller('MainCtrl', function($scope, $http) {
        $scope.min_score = 70;
        $scope.items = [];
        $scope.error = "";

        $scope.refresh = function() {
          $scope.error = "";
          $http.post('/api/query/wasm', { min_score: $scope.min_score })
            .then(function(res) {
              $scope.items = res.data;
            })
            .catch(function(err) {
              $scope.items = [];
              $scope.error = (err.data && (err.data.שגיאה || err.data.error))
                ? (err.data.שגיאה || err.data.error)
                : "שגיאה לא ידועה";
            });
        };

        $scope.refresh();
      });
  </script>
</body>
</html>
"""

@app.route("/")
def home():
    return render_template_string("""
    <html>
    <head>
      <meta charset="utf-8"/>
      <title>Hackossem - Home</title>
      <style>
        body {
          font-family: 'Segoe UI', sans-serif;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          margin: 0;
          padding: 0;
          min-height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
        }
        .container {
          background: white;
          border-radius: 12px;
          padding: 3rem;
          box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
          max-width: 500px;
          text-align: center;
        }
        h1 {
          color: #667eea;
          margin-bottom: 1rem;
          font-size: 2.5rem;
        }
        p {
          color: #666;
          margin-bottom: 2rem;
          font-size: 1rem;
          line-height: 1.6;
        }
        .menu {
          list-style: none;
          margin: 0;
          padding: 0;
        }
        .menu li {
          margin-bottom: 1rem;
        }
        .menu a {
          display: block;
          padding: 1rem;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          text-decoration: none;
          border-radius: 6px;
          font-weight: bold;
          transition: transform 0.2s, box-shadow 0.2s;
          font-size: 1.1rem;
        }
        .menu a:hover {
          transform: translateY(-2px);
          box-shadow: 0 6px 12px rgba(102, 126, 234, 0.4);
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>🚀 Hackossem</h1>
        <p>Explore demos and security labs</p>
        <ul class="menu">
          <li><a href="/vulnlab-ad-labs">🔐 VulnLab AD Labs</a></li>
          <li><a href="/linq">⚡ LINQ Demo</a></li>
          <li><a href="/wasm">🔧 WASM Demo</a></li>
        </ul>
      </div>
    </body>
    </html>
    """)

@app.route("/vulnlab-ad-labs")
def vulnlab_ad_labs():
    return render_template_string(VULNLAB_HTML)

@app.route("/linq")
def linq_page():
    return render_template_string(LINQ_HTML)

@app.route("/wasm")
def wasm_page():
    return render_template_string(WASM_HTML)

if __name__ == "__main__":
    print("✨ שרת פעיל: http://localhost:5000")
    app.run(debug=True, port=5000)
