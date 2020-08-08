%{
#include <stdio.h>
#include "y.tab.h"
int lex_line = 1;
int count = 0;

/*---------------Добавление информации о скобках---------------*/
struct bracket_info *add_bracket_info(int line, struct bracket_info *head, char bracket)
{
	struct bracket_info *dummy = head;
	if (dummy == NULL)
	{
		dummy = (struct bracket_info*)malloc(sizeof(struct bracket_info));
		dummy->line = line;
		dummy->opening_bracket = 0;
		dummy->closing_bracket = 0;
		dummy->more_closing = 0;
		dummy->pnext = NULL;
		head = dummy;
	}
	else
	{
		int find = 0;
		while(1)
		{
			if (dummy->line == line)
			{
				find = 1;
				break;
			}
			else if (dummy->pnext != NULL)
				dummy = dummy->pnext;
			else break;
		}
		if (find == 0)
		{
			dummy->pnext = (struct bracket_info*)malloc(sizeof(struct bracket_info));
			dummy = dummy->pnext;
			dummy->line = line;
			dummy->opening_bracket = 0;
			dummy->closing_bracket = 0;
			dummy->more_closing = 0;
			dummy->pnext = NULL;
		}
	}
	if (bracket == ')')
	{
		dummy->closing_bracket++;
		if (dummy->closing_bracket > dummy->opening_bracket)
			dummy->more_closing++;
	}
	else
		dummy->opening_bracket++;
	return head; 
}

/*---------------Структура описывающая каждое слагаемое---------------*/
struct letters 
{
	int what; // 1 - num*sym^(pow), 2 - num^(pow);
	int number; // Умножение на число или просто число. По дефолту ставить 1.
	int mul; // В случае, когда это num^(pow): pow != NULL. По дефолту ставить 1.
	struct letters *pow; // Возведение в степень. Если ее нет, то NULL.
	char symbol; // Символ переменной.
	char operation; // +-*. Символ умножения нужен для второй лабы.
	struct letters *pnext; // Указатель на следующий элемент.
	struct letters *pprev; // Указатель на предыдущий элемент.
	char op_check; // Для проверки ошибок нескольких знаков подряд
	char br_check; // Для проверки ошибок отсутствия знаков между скобками
};

/*---------------Создание узла---------------*/
struct letters *create_point_lex(int what, int number, struct letters *pow, char symbol, char operation)
{
	struct letters *new_one = (struct letters*)malloc(sizeof(struct letters));
	new_one->what = what;
	new_one->number = number;
	new_one->pow = pow;
	new_one->symbol = symbol;
	new_one->operation = operation;
	new_one->mul = 1;
	new_one->pnext = NULL;
	new_one->pprev = NULL;
	new_one->op_check = '0';
	new_one->br_check ='0';
	return new_one;
}

%}
%%

" " ;
"show:" {
    yylval.c = yytext[1];
    return(SHOW);
}
":" {
	yylval.c = yytext[0];
    return(BAD_SYM);
}
$[^\b]= {
    yylval.c = yytext[1];
    return(NEW_VAR);
}
$[^\b] {
	count++;
    yylval.c = yytext[1];
    return(VAR);
}
[0-9]+ {
	count++;
	yylval.point = create_point_lex(2, atoi(yytext), NULL, '0', '+');
    return(POLYNOMIAL);
}
[a-z] {
	count++;
	yylval.point = create_point_lex(1, 1, NULL, yytext[0], '+');
    return(POLYNOMIAL);
}
[-+(*/^)] {
	if ((yytext[0] == '*' || yytext[0] == '^') && count == 0)
	{
		yylval.c = yytext[0];
		return(BAD_SYM);
	}
	count++;
    if (yytext[0] == ')')
        bi_head = add_bracket_info(lex_line, bi_head, ')');
    else if (yytext[0] == '(')
        bi_head = add_bracket_info(lex_line, bi_head, '(');
    return(yytext[0]);
}
[^\b] {
    if (yytext[0] == 10)
    {
        yylval.c = yytext[0];
        lex_line++;
		count = 0;
        return(LF);
    }
	if (yytext[0] == 13)
        continue;
    yylval.c = yytext[0];
    return(BAD_SYM);
}
%%