#include <iostream>
#include <unordered_map>
#include <string>

using namespace std;

class VarInfo
{
    string type;
    string value;
    bool variable;
    // TO DO: Scope
};

class IDList
{
    unordered_map<string, string> IDs;

public:
    bool existsVar(const string name) const;
    void addVar(const string name, const string type);
    void printVars() const;
    ~IDList();
};
