%{
#include "header.h"
extern int line_counter;

%}

%union
{
	polynomial 	poly;
	monomial    mono;
	int 		num;
	char*		string;
}

/* declare tokens */

%token<string> STRING
%type<poly> polyplus polymulti polypower polyinit
%type<mono> monom
%type<string> variable

%token<num> NUMBER 
%token LBR RBR POW END PRINT EOL
%token NUMERR UNSUPPORTED
%left '+' '-'
%left '*' '/'
%right UMINUS
%right POW

%start start

%%


start:
	| start END
	| start EOL
	| start programm
	;
	
programm:
	variable '=' polyplus END
	{
		//printf("INIT variable %s\n", $1);
		init_variable($1, $3);
	}
	| PRINT variable END
	{
		polynomial tmp;
		tmp = search($2);
		if (tmp.begin == NULL) yyerror("Unknown variable");
		printf("Variable %s ", $2);
		pprint(&tmp);
	}
	| PRINT polyplus END
	{
		printf("Polynomial expression ");
		pprint(&$2);
	}
	/* pseudo rules */
	| variable '=' polyplus EOL 
	{	
		line_counter--;
		yyerror("Missing ';'");
	}
	| PRINT variable EOL
	{
		line_counter--;
		yyerror("Missing ';'");
	}
	| PRINT polyplus EOL 
	{
		line_counter--;
		yyerror("Missing ';'");
	}


polyplus:
	polyplus '+' polymulti
	{
		$$ = add_poly($1, $3);
	}
	| polyplus '-' polymulti

	{	
		$$ = sub_poly($1, $3);

	}
	| '-' polyplus %prec UMINUS
	{
		$$ = unary_poly(&$2);
	}
	| polymulti
	{
		$$ = $1;
	}
	/* pseudo rules */
	| polyplus '+' '+'
	{
		yyerror("Too much '+' operators in expression");
	}
	| polyplus '-' '-'
	{
		yyerror("Too much '-' operators in expression");
	}

polymulti:

	polymulti '*' polypower
	{
		$$ = multiply($1, $3);
	}
	| polymulti polypower
	{
		$$ = multiply($1, $2);
	}
	| polypower
	{
		$$ = $1;	

	}
	/* pseudo rules */
	| polymulti '*' '*'
	{
		yyerror("Too much '*' operators in expression");
	}
	| LBR '*' polymulti
	{
		yyerror("Misspelling expression");
	}
	| polymulti '*' RBR
	{
		yyerror("Misspelling expression");
	}
	| polymulti '/' polypower 
	{
		yyerror("Don't support division =(");
	}
;

polypower:

	polypower POW polyinit
	{
		polynomial temp = $3;
		polynomial temp2 = $1;
		//if (temp.begin->element.base == 0)
		//{
		//}
		int pow = temp.begin->element.kf;
		//printf("%d\n", pow);
		if (pow == 0)
		{
			
			if (temp2.begin->element.kf == 0)
			{
				yyerror("Zero to the power of zero undefined");
			}

			$$ = init_poly();
			monomial mono = init(1, "0", 0);
			$$ = add_monom($$, mono);
		}
		else if (pow == 1)
		{
			$$ = $1;
		}
		else if (pow > 1)
		{
			$$ = $1;
			for (int i = 0; i < pow - 1; i++)
			{
				$$ = multiply($$, $1);
			}
		}
		else
		{
			yyerror("Supports ONLY integer powers");
		}
	}
	| polyinit
	{
		$$ = $1;
	}
	/* pseudo rules */
	| polypower  POW POW 
	{
		yyerror("Too much '^' operators in expression");
	}
	| polypower POW '-'
	{
		yyerror("Don't support powers under zero = (");
	}	
	
	
;
	
polyinit:
	monom
	{
		$$ = init_poly();
		$$ = add_monom($$, $1);
	}
	| variable
	{ 
		polynomial poly;
		poly = init_poly();
		monomial mono = init(1, "0", 0);
		poly = add_monom(poly, mono);
		$$ = search($1); 
		$$ = multiply($$, poly);
	}
	| LBR polyplus RBR
	{
		$$ = $2;
	}
;

monom:

	NUMBER
	{
		$$ = init($1, "0", 0);
	}
	| STRING 
	{
		if (strlen($1) > 1) {
			yyerror("Invalid variable in polynomial expression");
		}
		$$ = init(1, $1, 1);
	}
	/* pseudorule */
	| NUMERR 
	{
		yyerror("Print numbers without zero in the beggining");
	}
	| UNSUPPORTED
	{
		yyerror("Don't support variables in powers");
	}

;

variable: '$' STRING
		{
			int size = strlen($2);
			$$ = (char*)malloc(sizeof(char)*(size+1));
			strncpy($$, $2, size+1);
			$$[size]='\0';
		}

	

%%

int main(int argc, char **argv)
{

#ifdef __linux__ 
    yyparse();

#elif _WIN32
    FILE* inputStream = fopen(argv[1], "r");
    if (inputStream == NULL)
    {
        printf("Can't found input file yyin.txt\n");
        exit(-1);
	}
    yyset_in(inputStream);
	yyparse();
    fclose(inputStream);
	return 0;

#endif


};


struct node* remove_node(polynomial *p, struct node *n) {

	struct node* res = n;

	if (p->begin == n)
	{
		if (n->next == NULL)
		{
			return NULL;
		}

		n->next->prev = NULL;
		res = n->next;
		p->begin = res;
		return res;
	}

	if (n->next == NULL)
	{
		n->prev->next = NULL;
		res = n->prev;
		return res;
	}

	n->next->prev = n->prev;
	n->prev->next = n->next;
	res = n->prev;
	return res;

}

polynomial addition_of_similar_terms(polynomial p)
{
	polynomial result = init_poly();
	monomial tmp_monom;
	struct node* tmp1 = p.begin;
	struct node* tmp2;
	while (tmp1 != NULL)
	{
		tmp_monom = tmp1->element;
		tmp2 = p.begin;

		while (tmp2 != NULL)
		{
			if (tmp1->element.power == tmp2->element.power && tmp1 != tmp2)
			{
				tmp_monom.kf += tmp2->element.kf;
				tmp2 = remove_node(&p, tmp2);
			}

			tmp2 = tmp2->next;
		}

		tmp1 = remove_node(&p, tmp1);
		result = add_monom(result, tmp_monom);
	}
	
	return result;
}



polynomial add_poly(polynomial p1, polynomial p2) {

	for (struct node* i = p1.begin; i != NULL; i = i->next) {
		char ibase = i->element.base[0];
		for (struct node* j = p2.begin; j != NULL; j = j->next) {
			char jbase = j->element.base[0];
			if (ibase != jbase && ibase!='0' && jbase!='0') yyerror("Sorry! Can't perform multivariable polynomial expressions =(");
			
		}
	}
	
	
	polynomial res = p1;
	struct node* tmp = p2.begin;

	res = add_monom(res, tmp->element);
	while (tmp->next != NULL) {
		tmp = tmp->next;
		res = add_monom(res, tmp->element);
	}
	// !!!!!
	return res = addition_of_similar_terms(res);
}


polynomial sub_poly(polynomial p1, polynomial p2) {

	return add_poly(p1, unary_poly(&p2));
}


polynomial add_monom(polynomial p, monomial m) {

	polynomial res;
	struct node* tmp;
	res = p;
	
	// идем от начала полинома
	tmp = res.begin;

	// если полином пустой, формируем его, добавляя моном 
	if (res.counter == 0)
	{
		tmp->element = m;
		res.counter++;
		return res;
	}

	// иначе идем в конец полинома 
	while (tmp->next != NULL)
	{
		tmp = tmp->next;
	}
	
	// цепляем наш моном	
	tmp->next = (struct node*)malloc(sizeof(struct node));
	tmp->next->prev = tmp;
	tmp->next->next = NULL;
	tmp = tmp->next;
	tmp->element = m;
	res.counter++;
	return res;

};


polynomial multiply(polynomial p1, polynomial p2) {
	
	polynomial res = init_poly();
	
	for (struct node *i = p1.begin; i != NULL; i = i->next)
	{
		for (struct node *j = p2.begin; j != NULL; j = j->next)
		{
			monomial monom = i->element;
			monom.kf *= j->element.kf;
						
			// оба не числа
			if (monom.base[0] != '0' && (monom.base[0] == j->element.base[0]))
			{
				monom.power += j->element.power;
			}
			else if (monom.base[0] == '0' && j->element.base[0] != '0')
			{
				monom.base[0] = j->element.base[0];
				monom.power += j->element.power;
			}
			else if (monom.base[0] != '0' && j->element.base[0] !='0' && (monom.base[0]!=j->element.base[0]))
			{
				yyerror("Sorry! Can't perform multivariable polynomial expressions =(");
			}

			if (monom.kf == 0)
			{
				
				monom.base[0] = '0';
				monom.power = 0;
			}

			res = add_monom(res, monom);
		}
	}

	res = addition_of_similar_terms(res);
	return res;

}

polynomial unary_poly(polynomial *p) {
	
	struct node* tmp = p->begin;

	while (tmp != NULL)
	{
		tmp->element.kf *= (-1);
		tmp = tmp->next;
	}

	return *p;
}

polynomial init_poly() {

	polynomial tmp;
	tmp.begin = (struct node *)malloc(sizeof(struct node));
	tmp.begin->prev = NULL;
	tmp.begin->next = NULL;
	tmp.counter = 0;
	return tmp;
};

monomial init(int kf, char* base, int power) {
	
	monomial tmp;
	tmp.kf = kf;
	tmp.base[0] = base[0];
	tmp.base[1] = '\0';
	tmp.power = power;
	return tmp;

};

void mprint(monomial* m) {

	if (m->base[0] == '0')
	{
		printf("%d", m->kf);
	}
	else
	{
		if (abs(m->kf) == 1)
		{
			if (m->kf == -1)
			{
				printf("-");
			}
			if (m->power == 1)
			{
				printf("%s", m->base);
			}
			else
			{
				printf("%s^%d", m->base, m->power);
			}
		}
		else
		{
			if (m->power == 1)
			{
				printf("%d%s", m->kf, m->base);
			}
			else
			{
				if (m->kf == 1)
				{
					printf("%s^%d", m->base, m->power);
				}
				else
				{
					printf("%d%s^%d", m->kf, m->base, m->power);
				}
			}
		}
	}
	
}

struct var* global_var_list;
int var_counter = 0;


polynomial search(char* name) {
	
	for (int i = 0; i < var_counter;i++) if (!strcmp(name, global_var_list[i].varname)) return global_var_list[i].polynom;
	yyerror("Unknown variable");
}

int check_in_global_list(char* name) {
	
	for (int i = 0; i < var_counter; i++) if (!strcmp(name, global_var_list[i].varname)) return 1;
    return 0;
	
}
void replace(char* name, polynomial polynom) {
	
	for (int i = 0; i < var_counter;i++) {
		if (!strcmp(name, global_var_list[i].varname)) {
			global_var_list[i].polynom = polynom;
			return;
		}
	}
}

void init_variable(char* name, polynomial polynom) {
	
	struct var variable;
	int size = strlen(name);
	variable.varname = (char*)malloc(sizeof(char)*(size+1));
	strncpy(variable.varname, name, size);
	variable.varname[size]='\0';
	variable.polynom = polynom;
	if (var_counter == 0) global_var_list = (struct var*)malloc(sizeof(struct var)*(var_counter+1));
	else {
		if(!check_in_global_list(name)) global_var_list = (struct var*)realloc(global_var_list, sizeof(struct var)*(var_counter+1));
		else {
			printf("WARNING in line %d: Variable '$%s' reinitialization\n", line_counter+1, name);
			replace(name, polynom);
			return;
		}
	}
	global_var_list[var_counter] = variable;
	var_counter++;
	
}
	


void pprint(polynomial* p) {

	struct node *begin = p->begin;
	printf("= ");
	
	while (begin->element.kf == 0 && begin->next != NULL) begin = begin->next;
	int itemNum = 0;
	//printf("my = %d\n", p->counter);
	for (struct node *tmp = begin; tmp != NULL; tmp = tmp->next) itemNum++;
	int *itemWasPrinted = (int*)calloc(sizeof(int), itemNum);

	char varName[2] = "0";
	for (struct node *tmp = begin; tmp != NULL; tmp = tmp->next)
	{
		if (strncmp(tmp->element.base, "0", 2) != 0) strncpy(varName, tmp->element.base, 2);	
		
	}
	int firstWasPrinted = 0;
	//Вывести все одночлены с этой переменной
	for (int i = 0; i < itemNum; i++)
	{
		//Найти самую старшую невыведенную степень
		int maxPower = 0;
		int currentItemIndex = 0;
		int itemIndex = 0;
		struct node *result = begin;
		for (struct node *tmp = begin; tmp != NULL; tmp = tmp->next)
		{
			if (strncmp(tmp->element.base, varName, 2) == 0 && //Если совпадает имя переменной
				itemWasPrinted[currentItemIndex] == 0 &&					  //Эта переменная не была выведена
				tmp->element.power > maxPower)					  //Cтепень выше других
			{
				result = tmp;
				maxPower = tmp->element.power;
				itemIndex = currentItemIndex;
			}

			currentItemIndex++;
		}

		if (maxPower != 0)//Если был найден хоть один подходящий элемент, то
		{
			//Вывести найденный элемент
			if (firstWasPrinted && result->element.kf > 0)//Если уже были выведены значения и коэффициент положительный
			{
				printf("+");
			}
			if (result->element.kf != 0) {
				firstWasPrinted = 1;
				mprint(&result->element);
				//printf("kdkdk\n");
				itemWasPrinted[itemIndex] = 1;
			}
			
		}
		else
		{
			break;//Если нового невыведенного элемента не было найдено, то можно перейти к следующей переменной
		}
	}
	
	for (struct node *tmp = begin; tmp != NULL; tmp = tmp->next)
	{
		if (strncmp(tmp->element.base, "0", 2) == 0 && tmp->element.kf != 0)
		{
			if (firstWasPrinted && tmp->element.kf > 0) //Если уже были выведены значения и коэффициент положительный
			{
				printf("+");
			}

			firstWasPrinted = 1;
			mprint(&tmp->element);
			//printf("qwqwqqw\n");
			break;
		}
	}

	//Вывести 0, если совсем ничего не было выведено
	if (!firstWasPrinted) printf("0");
	
	printf(".\n");
	

}

int yyerror(char *msg)
{
    fprintf(stderr, "ERROR IN LINE %d : %s\n", line_counter+1, msg);
	exit(-1);
	
}