#include <iostream>
#include <unordered_map>
#include <string>

using namespace std;

bool isPlainType(const char *type);
const char* prettyExprType(const char* type);

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
    VarInfo *array;

    string customType;
    class IDList *fields;

    bool isVariable;
    bool wasInitialized;

    string scope;

    VarInfo();
    VarInfo(const char type, const bool variable, const int size, const string scope);
    VarInfo(const string type, const bool variable, const int size, const string scope, const class CustomTypesList *cts);
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
    bool isInScope(const string name, const string scope);
    void addVar(const string name, const bool variable, const char type, const string scope);
    void addArrayVar(const string name, const bool variable, const string type, const int size, const string scope);
    void addCustomVar(const string name, const bool variable, const string type, const string scope, const CustomTypesList *cts);
    VarInfo *accessCustomField(const string name, const string field);
    void setValue(const string name, const char *value);
    void copyValue(const string name, const class VarInfo* target);
    void printVars(const bool compact) const;
    IDList& operator+=(IDList& other);
    ~IDList();
};

class CustomTypesList
{
public:
    unordered_map<string, IDList*> CustomTypes;

    bool existsCustom(const string name) const;
    void addCustom(const string name, IDList* contents);
    void printCustoms() const;
    ~CustomTypesList();
};

class FunInfo
{
public:
    string returnType;
    int nParam;
    IDList params;
    bool hasOther;
    IDList other;
    FunInfo(const char* returnType, IDList* params, IDList* other);
};

class FunctionsList
{
public:
    unordered_map<string, FunInfo> Funs;
    void addFun(const char* name, const char* retType, IDList* params, IDList* other);
    void printFuns() const;
};

class ASTNode
{
public:
    string type;
    bool typeComputed;
    string rawValue;
    class ASTNode* left;
    class ASTNode* right;
    ASTNode(const char* type, const char* rawValue);
    ASTNode(const VarInfo& ref);
    const char* computeType(bool& triggerErr);
    int computeIntVal(bool& triggerErr);
    float computeFloatVal(bool& triggerErr);
    bool computeBoolVal(bool& triggerErr);
    void destroyTree();
};