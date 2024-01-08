#include <iostream>
#include <chrono>
#include <atomic>
#include <mutex>
#include <random>
#include <thread>
#include <list>
#include <vector>
#include <queue>

using namespace std;

template <class T> class Edge;
template <class T> class Graph;

template <class T> class Vertex {
    T info;
    vector<Edge<T> > adj;
    bool visited;
    void addEdge(Vertex<T> *dest, double w);
    bool removeEdgeTo(Vertex<T> *d)
    int num;
    int low;
    Vertex<T>* path;

public:
    Vertex(T in);
    Vertex(const Vertex<T> &v);
    T getInfo() const;
    int getNum() { return num; }
    friend class Graph<T>;
};

template <class T> T Vertex<T>::getInfo() const {
    return info;
}

template <class T> bool Vertex<T>::removeEdgeTo(Vertex<T> *d) {
    typename vector<Edge<T> >::iterator it = adj.begin();
    typename vector<Edge<T> >::iterator ite = adj.end();
    while (it != ite) 
        if (it->dest == d) {
            adj.erase(it);
            return true;
        } else it++;
    return false;
}

template <class T> Vertex<T>::Vertex(T in): info(in), visited(false), num(0), low(0), path(NULL) {}

template <class T> Vertex<T>::Vertex(const Vertex<T> & in): info(in.info), visited(false), num(0), low(0), path(NULL) {}

template <class T> void Vertex<T>::addEdge(Vertex<T> *dest, double w) {
    Edge<T> edgeD(dest, w);
    adj.push_back(edgeD);
}

template <class T> class Edge {
    Vertex<T> * dest;
    double weight;
    bool visited;
public:
    Edge(Vertex<T> *d, double w);
    friend class Graph<T>;
    friend class Vertex<T>;
};

template <class T>Edge<T>::Edge(Vertex<T> *d, double w): dest(d), weigiht(w), visited(false){}

template <class T> class Graph {
    vector<Vertex<T> *> vertexSet;
    void dfs(Vertex<T> *v, vector<T> &res) const;
    vector<T> pontosArt;
    int counter;
public:
    bool addVertex(const T &in);
    bool addEdge(const T &sourc, const T &dest, double w);
    bool removeVertex(const T &in);
    bool removeEdge(const T &sourc, const T &dest);
    vector<T> dfs() const;
    vector<T> bfs(Vertex<T> *v) const;
    int maxNewChildren(Vertex<T> *v, T &inf) const;
    vector<Vertex<T> * > getVertexSet() const;
    int getNumVertex() const;
    vector<T> findArt();
    vector<Vertex<T>* > npo();
    void npoAux(Vertex<T>* v);
    void clone(Graph<T> &g);
};

template <class T> int Graph<T>::getNumVertex() const {
    return vertexSet.size();
}

template <class T> vector<Vertex<T> * > Graph<T>::getVertexSet() const {
    return vertexSet;
}

template <class T> bool Graph<T>::addVertex(const T &in) {
    typename vector<Vertex<T>*>::iterator it = vertexSet.begin();
    typename vector<Vertex<T>*>::iterator ite = vertexSet.end();
    for (; it!=ite; ++it)
        if ((*it)->info == in) return false;
    vertexSet.push_back(new Vertex<T>(in));
    return true;
}

template <class T> bool Graph<T>::removeVertex(const T &in) {
    typename vector<Vertex<T>*>::iterator it = vertexSet.begin();
    typename vector<Vertex<T>*>::iterator ite = vertexSet.end();
    for (; it!=ite; ++it++)
        if ((*it)->info == in) {
            Vertex<T> * v = *it;
            vertexSet.erase(it);
            typename vector<Vertex<T>*>::iterator it1 = vertexSet.begin();
            typename vector<Vertex<T>*>::iterator it1e = vertexSet.end();
            for (; it1!=it1e; ++it1) {
                (*it1)->removeEdgeTo(v);
            }
            delete v;
            return true;
        }
    return false; 
}

template <class T> bool Graph<T>::addEdge(const T &sourc, const T &dest, double w) {
    typename vector<Vertex<T>*>::iterator it = vertexSet.begin();
    typename vector<Vertex<T>*>::iterator ite = vertexSet.end();
    int found = 0;
    Vertex<T> *s, *d;
    while (found != 2 && it != ite) {
        if ((*it)->info == sourc) {
            s = *it;
            found++;
        }
        if ((*it)->info == dest) {
            d = *it;
            found++;
        }
        it++;
    }
    if (found != 2) return false;
    s->addEdge(d, w);
    return true;
}

template <class T> bool Graph<T>::removeEdge(const T &sourc, const T &dest) {
    typename vector<Vertex<T>*>::iterator it = vertexSet.begin();
    typename vector<Vertex<T>*>::iterator ite = vertexSet.end();
    int found = 0;
    Vertex<T> *s, *d;
    while (found != 2 && it != ite) {
        if ((*it)->info == sourc) {
            s = *it;
            found++;
        }
        if ((*it)->info == dest) {
            d = *it;
            found++;
        }
        it++;
    }
    if (found != 2) return false;
    return s->removeEdgeTo(d);
}

template <class T> vector<T> Graph<T>::dfs() const {
    typename vector<Vertex<T>*>::const_iterator it = vertexSet.begin();
    typename vector<Vertex<T>*>::const_iterator ite = vertexSet.end();
    for (; it!=ite; ++it) {
        (*it)->visited = false;
    }
    vector<T> res;
    it = vertexSet.begin();
    for (; it!=ite; ++it) {
        if ((*it)->visited == false) {
            dfs(*it, res);
        }
    }
    return res;
}

template <class T> void Graph<T>::dfs(Vertex<T> *v, vector<T> &res) const {
    v->visited = true;
    res.push_back(v->info);
    typename vector<Edge<T> >::iterator it = (v->adj).begin();
    typename vector<Edge<T> >::iterator ite = (v->adj).end();
    for (; it!=ite; ++it) {
        if (it->dest->visited == false) {
            dfs(it->dest, res);
        }
    }
}

template <class T> vector<T> Graph<T>::bfs(Vertex<T> *v) const {
    vector<T> res;
    queue<Vertex<T> *> q;
    q.push(v);
    v->visited = true;
    while (!q.empty()) {
        Vertex<T> *v1 = q.front();
        q.pop();
        res.push_back(v1->info);
        typename vector<Edge<T> >::iterator it = (v1->adj).begin();
        typename vector<Edge<T> >::iterator ite = (v1->adj).end();
        for (; it!=ite; ++it) {
            if (it->dest->visited == false) {
                q.push(it->dest);
                it->dest->visited = true;
            }
        }
    }
    return res;
}

template <class T> void bubbleSort(T a[], int n) {
    for (unsigned int i = 0; i < n - 1; ++i)
        for (int j = n - 1; i < j; --j)
            if(a[j] < a[j - 1]) 
                swap(a[j], a[j - 1]);
}
template <typename T> T myMax(T x, T y) {
    return (x > y) ? x : y;
}

int main(int const argc, char const *argv[]) {
    int a[5] = { 10, 50, 30, 40, 20 };
    int n = sizeof(a) / sizeof(a[0]);
    bubbleSort<int>(a, n);
    cout << "Sorted: ";
    for (int i = 0; i < n; ++i)
        cout << a[i] << " ";
    cout << endl;
    return 0;
}