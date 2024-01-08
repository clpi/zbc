#include <algorithm>
#include <iostream>
#include <set>
#include <sstream>
#include <vector>
#include <map>
#include <string>
#include <unordered_set>

using namespace std;

const std::vector<std::string> colors = {
    "PINK", "ORANGE", "CYAN",
    "YELLOW", "GREEN", "BLUE", "RED",
};

class Node {
public:
    Node(const int32_t& aId, const int32_t& aSat, const std::string& aCol)
        : id(aId), sat(aSat), col(aCol) {}

    Node() : id(0), sat(0), col("NO_COLOUR") {}

    int32_t id, sat;
    std::string col;
    bool excluded = false;
};

int main(int const argc, const char* argv[]) {
    int32_t n, m;
    cin >> n >> m;
    vector<Node> nodes(n);
    for (int32_t i = 0; i < n; ++i) {
        nodes[i].id = i;
        cin >> nodes[i].sat;
    }
    for (int32_t i = 0; i < n; ++i) {
        cin >> nodes[i].col;
    }
    for (int32_t i = 0; i < m; ++i) {
        int32_t a, b;
        cin >> a >> b;
        nodes[a].excluded = true;
        nodes[b].excluded = true;
    }
    vector<Node> nodes_copy = nodes;
    sort(nodes_copy.begin(), nodes_copy.end(), [](const Node& a, const Node& b) {
        return a.sat > b.sat;
    });
    for (int32_t i = 0; i < n; ++i) {
        if (nodes_copy[i].excluded) {
            continue;
        }
        for (int32_t j = 0; j < colors.size(); ++j) {
            if (nodes_copy[i].col == colors[j]) {
                continue;
            }
            nodes_copy[i].col = colors[j];
            break;
        }
    }
    for (int32_t i = 0; i < n; ++i) {
        cout << nodes_copy[i].col << " ";
    }
    cout << endl;
    return 0;
}