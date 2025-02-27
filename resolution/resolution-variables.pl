:- ["./utils/read.pl", "./utils/parse.pl", "./utils/utils.pl"].

/* Given a clause, a list with multiple terms, extract
 * all the variables from the clause.
 * */
get_variables_from_clause(Clause, Variables) :- 
    maplist(term_variables, Clause, VariablesList),
    flatten(VariablesList, FlatVariables),
	sort(FlatVariables, Variables).

/* Given a knowledge base, for each clause, replace
 * all of its variables with new ones, in order to make
 * each variable from a clause independent from the variables
 * from other clauses.
 * */
replace_vars_from_clause([], []).
replace_vars_from_clause([Clause|KB], [NewClause|NewKB]) :-
    get_variables_from_clause(Clause, Variables),
    copy_term(Variables, Clause, _, NewClause),
    replace_vars_from_clause(KB, NewKB).

/* Given two clauses and a literal, removes the literal
 * from the first clause and the negated literal from
 * the second clause, then concatenates the results.
 *
 * NOTE: it is assumed that the Literal will certainly 
 * lead to a Resolvent for the given clauses.     
 * */
make_resolvent(Clause1, Clause2, Literal, Resolvent) :-
    eliminate(Literal, Clause1, Clause1New),	% eliminate literal from the first clause
    neg(Literal, LiteralNeg),
    eliminate(LiteralNeg, Clause2, Clause2New),	% eliminate negated literal from the second clause
    merge(Clause1New, Clause2New, Resolvent).   % merge the newly resulted clauses 

/* Given two clauses, searches for a literal
 * that could generate a resolvent for them.
 * */
do_resolve([], _, []).
do_resolve([H1|T1], Clause, Literal) :- 
    neg(H1, H2), member(H2, Clause), Literal = H1, !; 
    do_resolve(T1, Clause, Literal).

/* Given a knowledge base and a clause, search for another
 * clause in the knowledge base that could make a resolvent
 * with the given clause.
 * */
search_matching_clause([], [], [], [], [], []).
search_matching_clause([Clause|KB], KBOriginal, Resoluted, TargetClause, Matching, Resolvent) :-
    % make a copy of the clauses for checking
    copy_term(TargetClause, TargetClauseSubst),
    copy_term(Clause, ClauseSubst),
    is_not_member([TargetClause, Clause], Resoluted),
    % check if the copies resolve
    do_resolve(TargetClauseSubst, ClauseSubst, Literal), Literal \= [], 
    make_resolvent(TargetClauseSubst, ClauseSubst, Literal, Resolvent), is_not_member(Resolvent, KBOriginal),
    % if they do, save the clauses that matched the target clause
    Matching = Clause, !;
    search_matching_clause(KB, KBOriginal, Resoluted, TargetClause, Matching, Resolvent).

/* Given a knowledge base, searches for two clauses
 * that might form a resolvent.
 * 
 * Clause 1 is compared with Clause 2, Clause 3, Clause 4, ..., Clause n.
 * Clause 2 is compared with --------, Clause 3, Clause 4, ..., Clause n.
 * Clause 3 is compared with --------, --------, Clause 4, ..., Clause n.
 * */
search_clauses([], [], [], [], [], []).
search_clauses([Clause|KB], KBOriginal, Resoluted, Clause, Matching, Resolvent) :- 
    search_matching_clause(KB, KBOriginal, Resoluted, Clause, Matching, Resolvent), Matching \= [], !.
search_clauses([_|KB], KBOriginal, Resoluted, Clause, Matching, Resolvent) :-
    search_clauses(KB, KBOriginal, Resoluted, Clause, Matching, Resolvent).

/* Given a list of lists, where negation of predicates as 
 * denoted as n(X), applies the resolution algorithm to see 
 * if the predicates are unsatisfiable or satisfiable.
 * */
resolution_helper(KB, _, Result) :- 
    member([], KB), Result = "UNSATISFIABLE", write(Result), nl, !.
resolution_helper(KB, Resoluted, Result) :-
    search_clauses(KB, KB, Resoluted, Clause, Matching, Resolvent),
    Clause \= [], Matching \= [],
    resolution_helper([Resolvent|KB], [[Clause, Matching]|Resoluted], Result), !.
resolution_helper(_, _, Result) :- 
    Result = "SATISFIABLE", write(Result), nl.

/* Given a KB, replaces all of its variables and runs the resolution algorithm.
 * */
resolution(KB, Result) :- replace_vars_from_clause(KB, KBNew), resolution_helper(KBNew, [], Result).

/* Given a list of KBs, apply the resolution
 * algorithm on every single KB.
 * */
resolution_on_list([]).
resolution_on_list([KB|KBs]) :-
    write("Resolution for:"), nl,
    write(KB), nl, 
    resolution(KB, _), nl, nl,
    resolution_on_list(KBs). 

/* Applies resolution to all KBs from a file. */
solve :-
    read_file("./inputs/resolution-variables.txt", KBs),
    process_sentences(KBs, KBParsed),
    resolution_on_list(KBParsed).

/* Applies resolution to the football knowledge base. */
solve_football :-
    read_file("./inputs/football.txt", KBs),
    unpack_kb(KBs, KB),
    process_sentence(KB, KBParsed),
    write(KBParsed), nl,
    resolution(KBParsed, _).