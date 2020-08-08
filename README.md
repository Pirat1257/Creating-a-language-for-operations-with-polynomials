# Creating-a-language-for-operations-with-polynomials
Formal grammars and compiler theory

Цель: Проектирование и реализация собственного формального языка.

Задание: Спроектировать и реализовать понятный и удобный язык работы с полиномами.

Требования:
  - Продуманный синтаксис. Для максимального удобства синтаксис должен быть максимально похож на математический. Применять общепринятые правила записи операций с полиномами;
  - Появляются полиномы от разных переменных (x, y, z и т.п.). Если в выражении участвует одна переменная, то все должно посчитаться без ошибок. Если в выражении появляются разные переменные, например, (2x+1)*(y-x), то выводить ошибку;
  - Появляются переменные, которым можно присваивать полиномы. Например, $A=x+1 означает, что переменной $A присваивается x+1. Далее, в любом месте, где можно использовать полином в явном виде, можно использовать переменную типа полином. Также, переменную можно выводить на экран. Синтаксис самих переменных, оператора присваивания и вывода на печать придумайте исходя из удобства языка;
  - Теперь программа на вашем языке должна помещаться во входной файл (а не просто в stdin), откуда она считывается и исполняется;
  - Появляются развернутые сообщения об ошибках с указанием номера строки, где они произошли. Как минимум, должны появиться по 2-3 сообщения для каждого типа возможных ошибок:
    - лексические. Определяются на этапе лексического анализа (lex);
    - синтаксические. Определяются на этапе синтаксического анализа (yacc);
    - семантические. Определяются на этапе исполнения.

win_bison и win_flex: https://sourceforge.net/projects/winflexbison/;

Команды для сборки и запуска проекта:
  - Linux:
    - yacc -d -y lab_2.y;
    - lex lab_2.y;
    - gcc y.tab.c lex.yy.c;
    - ./a.out.
  - Windows:
    - win_bison -d -y lab_2.y;
    - win_flex lab_2.l;
    - gcc y.tab.c lex.yy.c;
    - a.exe.

Описание реализованной грамматики языка:
  - Терминалы:
    - POLYNOMIAL - цифра или переменная;
    - SHOW - команда печати;
    - BAD_SYM – неразрешенный или ошибочный символ, используется для развернутого сообщения об ошибке;
    - VAR – глобальная переменная-полином;
    - NEW_VAR – объявление новой глобальной переменной-полинома.
  - Нетерминалы:
    - Начальным нетерминалом является start;
    - start ⇾ begin (основная часть есть все обработанные полиномы);
    - begin ⇾ begin each_line (обработанные полиномы есть обработанные полиномы и следующий за ними обработанный полином);
    - begin ⇾ begin show each_line (обработанные полиномы есть обработанные полиномы и следующая за ними операция вывода обработанного полинома);
    - show ⇾ SHOW (операция вывода полинома);
    - each_line ⇾ polynomial (обработанный полином есть полином);
    - each_line ⇾ NEW_VAR each_line (обработанный полином есть объявление новой глобальной переменной-полинома);
    - polynomial ⇾ VAR (полином есть глобальная переменная-полином);
    - polynomial ⇾ polynomial ‘^’ polynomial (полином есть операция возведения в степень между двумя полиномами);
    - polynomial ⇾ polynomial ‘*’ polynomial (полином есть операция умножения между двумя полиномами);
    - polynomial ⇾ ‘(‘ polynomial ‘)’ (полином есть полином в скобках);
    - polynomial ⇾ polynomial polynomial (полином есть операция сложения между двумя полиномами);
    - polynomial ⇾ ‘+’ polynomial (полином есть полином умноженный на единицу);
    - polynomial ⇾ ‘-’ polynomial (полином есть полином умноженный на минус единицу);
    - polynomial ⇾ POLYNOMIAL (полином есть цифра или переменная).

Некоторые особенности разработанной грамматики:
  - Входные данные помещаются во входной файл input.txt;
  - Во входном файле все полиномы, объявления глобальных переменных и команды задаются с новой строки;
  - В одной строке можно объявить несколько глобальных переменных;
  - Команды могут использоваться в любом месте;
  - Допускается использование пробелов;
  - При объявлении и последующем использовании глобальной переменной используется символ «$», за которым должна следовать заглавная латинская буква, в противном случае это будет являться ошибкой;
  - Использование полиномов с различными переменными недопустимо и является ошибкой;
  - Вывод полинома производится с помощью команды «show:».
