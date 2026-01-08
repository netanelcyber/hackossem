from flask import Flask, jsonify, request, render_template_string

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

# ==========================================
# 3) API: שאילתת LINQ בפייתון
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
# 5) דפי AngularJS (עברית)
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
    <div dir="rtl" style="font-family:sans-serif;padding:2rem">
      <h2>בחר דמו</h2>
      <ul>
        <li><a href="/linq">LINQ בפייתון</a></li>
        <li><a href="/wasm">WASM (JIT → x86_64 Windows)</a></li>
      </ul>
    </div>
    """)

@app.route("/linq")
def linq_page():
    return render_template_string(LINQ_HTML)

@app.route("/wasm")
def wasm_page():
    return render_template_string(WASM_HTML)

if __name__ == "__main__":
    print("✨ שרת פעיל: http://localhost:5000")
    app.run(debug=True, port=5000)
