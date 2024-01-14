#include <iostream>
#include <unordered_map>
#include <string>

using namespace std;

class VarInfo
{
public:
    char type;
    
    int intVal = 0;
    float floatVal = 0;
    char charVal = 0;
    string stringVal = "";
    bool boolVal = false;

    bool variable;
    // TO DO: Scope
    VarInfo(char type, bool variable);
    ~VarInfo();
};

class IDList
{
public:
    unordered_map<string, VarInfo> IDs;

    bool existsVar(const string name) const;
    void addVar(const string name, const char type);
    void setValue(const string name, const char* value);
    void printVars() const;
    ~IDList();
};
