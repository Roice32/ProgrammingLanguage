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


    int arrSize;
    VarInfo* array;

    string customType;
    class IDList* fields;

    bool isVariable;
    // TO DO: Scope
    VarInfo();
    VarInfo(const char type, const bool variable, const int size);
    VarInfo(const string type, const bool variable, const int size, const class CustomTypesList* cts);
    void printType() const;
    void printPlainVal() const;
    void printArray() const;
    void printCustomVar() const;
    ~VarInfo();
};

class IDList
{
public:
    unordered_map<string, VarInfo> IDs;

    bool existsVar(const string name) const;
    void addVar(const string name, const char type);
    void addArrayVar(const string name, const char type, const int size);
    void addCustomVar(const string name, const string type, const CustomTypesList* cts);
    VarInfo* accessCustomField(const string name, const string field);
    void setValue(const string name, const char* value);
    void printVars() const;
    ~IDList();
};

class CustomTypesList
{
public:
    unordered_map<string, IDList> CustomTypes;
    
    bool existsCustom(const string name) const;
    void addCustom(const string name, const IDList contents);
    void printCustoms() const;
    ~CustomTypesList();
};