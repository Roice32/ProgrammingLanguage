#include <iostream>
#include <unordered_map>
#include <string>

using namespace std;

class IDList
{
    unordered_map<string, string> IDs;
   
    public:
    bool existsVar(const string name) const;
    void addVar(const string name, const string type);
    void printVars() const;
    ~IDList();
};
