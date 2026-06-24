# Libasm — Assembly yourself!

> Projet 42 — Familiarisation avec le langage assembleur x86-64

---

## Table des matières

- [Introduction](#introduction)
- [Concepts fondamentaux](#concepts-fondamentaux)
  - [Qu'est-ce que l'assembleur ?](#quest-ce-que-lassembleur-)
  - [NASM et la syntaxe Intel](#nasm-et-la-syntaxe-intel)
  - [Les registres x86-64](#les-registres-x86-64)
  - [La calling convention System V AMD64](#la-calling-convention-system-v-amd64)
  - [Les syscalls Linux](#les-syscalls-linux)
  - [La gestion de errno](#la-gestion-de-errno)
  - [Le flag `-fPIC` et la position indépendante du code](#le-flag--fpic-et-la-position-indépendante-du-code)
- [Structure d'un fichier `.s` NASM](#structure-dun-fichier-s-nasm)
- [Instructions essentielles](#instructions-essentielles)
- [Fonctions implémentées](#fonctions-implémentées)
  - [Partie obligatoire](#partie-obligatoire)
  - [Partie bonus](#partie-bonus)
- [Makefile](#makefile)
- [Conseils & pièges courants](#conseils--pièges-courants)

---

## Introduction

**Libasm** est un projet de l'école 42 dont l'objectif est de réécrire des fonctions de la libc standard en **langage assembleur x86-64**. Le projet force à comprendre ce qui se passe réellement sous le capot : comment les arguments sont passés, comment les valeurs sont retournées, comment les erreurs système sont gérées.

**Contraintes techniques :**
- Assembleur **64-bit** uniquement
- Syntaxe **Intel** (pas AT&T)
- Compilateur : **NASM**
- Fichiers source : extension `.s`
- Pas d'inline ASM (pas de `asm(...)` dans du C)
- Interdiction du flag de compilation `-no-pie`

---

## Concepts fondamentaux

### Qu'est-ce que l'assembleur ?

L'assembleur est un langage de bas niveau avec une correspondance quasi directe avec le **machine code** du processeur.Il est **spécifique à une architecture** — ici `x86-64` (aussi appelé AMD64).

On appelle aussi l'assembleur du **symbolic machine code** : chaque instruction (`mov`, `add`, `cmp`…) correspond directement à un opcode processeur.

Le code assembleur est transformé en code machine par un **assembleur** (le programme NASM ici), puis lié par un **linker** (`ld` ou via `gcc`).

---

### NASM et la syntaxe Intel

**NASM** (Netwide Assembler) est l'assembleur utilisé dans ce projet. Il utilise la **syntaxe Intel**, dont la convention est :

```nasm
instruction destination, source
```

Exemples :
```nasm
mov rax, 5        ; rax = 5
mov rax, [rbx]    ; rax = valeur à l'adresse pointée par rbx
add rax, rcx      ; rax = rax + rcx
```

La syntaxe AT&T (utilisée par GCC/GAS) est l'inverse (`mov src, dst`) et utilise des préfixes `%` pour les registres et `$` pour les constantes — à ne pas confondre.

---

### Les registres x86-64

Les registres sont des emplacements de stockage ultra-rapides **dans le processeur**. En x86-64, les registres généraux sont 64-bit :

| Registre 64-bit | 32-bit | 16-bit | 8-bit | Rôle conventionnel |
|:-:|:-:|:-:|:-:|:--|
| `rax` | `eax` | `ax` | `al` | Valeur de retour / accumulateur |
| `rbx` | `ebx` | `bx` | `bl` | Sauvegardé par l'appelé (callee-saved) |
| `rcx` | `ecx` | `cx` | `cl` | 4ème argument |
| `rdx` | `edx` | `dx` | `dl` | 3ème argument |
| `rsi` | `esi` | `si` | `sil` | 2ème argument |
| `rdi` | `edi` | `di` | `dil` | 1er argument |
| `rsp` | `esp` | `sp` | `spl` | Stack pointer (sommet de la pile) |
| `rbp` | `ebp` | `bp` | `bpl` | Base pointer (frame de la pile) |
| `r8`  | `r8d` | `r8w` | `r8b` | 5ème argument |
| `r9`  | `r9d` | `r9w` | `r9b` | 6ème argument |
| `r10`–`r11` | — | — | — | Temporaires (clobbered by call) |
| `r12`–`r15` | — | — | — | Callee-saved |

> ⚠️ Écrire dans `eax` (32-bit) **zero-étend** automatiquement vers `rax` (64-bit). Ce n'est pas le cas pour les registres 8 ou 16-bit.

**Registres spéciaux :**
- `rip` — Instruction Pointer (compteur de programme, non modifiable directement)
- `rflags` — Flags du processeur (ZF, CF, SF, OF…)

---

### La calling convention System V AMD64

C'est **la convention d'appel** utilisée sur Linux/macOS x86-64. Elle définit les règles que tout le code doit respecter pour que les fonctions C et assembleur puissent s'appeler mutuellement.

#### Passage des arguments

Les 6 premiers arguments **entiers/pointeurs** sont passés dans les registres, dans cet ordre :

| Argument | Registre |
|:--------:|:--------:|
| 1er | `rdi` |
| 2ème | `rsi` |
| 3ème | `rdx` |
| 4ème | `rcx` |
| 5ème | `r8` |
| 6ème | `r9` |

Au-delà de 6 arguments, ils sont poussés sur la pile.

Les arguments **virgule flottante** utilisent `xmm0`–`xmm7`.

#### Valeur de retour

- Entiers/pointeurs : retournés dans `rax` (et `rdx` pour les types 128-bit)
- Flottants : retournés dans `xmm0`

#### Registres callee-saved vs caller-saved

| Catégorie | Registres | Signification |
|:--|:--|:--|
| **Caller-saved** (volatiles) | `rax`, `rcx`, `rdx`, `rsi`, `rdi`, `r8`–`r11` | L'appelant doit les sauvegarder s'il en a besoin après le `call` |
| **Callee-saved** (non-volatiles) | `rbx`, `rbp`, `r12`–`r15` | La fonction appelée DOIT les restaurer avant de `ret` |

#### Alignement de la pile

La pile **doit être alignée sur 16 octets** au moment de l'instruction `call`. Après un `call`, `rsp` est décalé de 8 (adresse de retour), donc au début d'une fonction `rsp % 16 == 8`. Pour appeler une autre fonction depuis l'assembleur, il faut souvent ajuster la pile.

---

### Les syscalls Linux

Un **syscall** est une demande au noyau Linux d'effectuer une opération privilégiée (lire un fichier, écrire, allouer de la mémoire…). En x86-64 Linux, les syscalls se font via l'instruction `syscall`.

**Convention pour les syscalls Linux x86-64 :**

| Élément | Registre |
|:--|:--|
| Numéro du syscall | `rax` |
| 1er argument | `rdi` |
| 2ème argument | `rsi` |
| 3ème argument | `rdx` |
| 4ème argument | `r10` |
| 5ème argument | `r8` |
| 6ème argument | `r9` |
| Valeur de retour | `rax` |

**Numéros de syscalls utiles (Linux x86-64) :**

| Syscall | Numéro | Prototype |
|:--|:--:|:--|
| `read` | `0` | `read(fd, buf, count)` |
| `write` | `1` | `write(fd, buf, count)` |
| `exit` | `60` | `exit(status)` |

En cas d'erreur, le syscall retourne une valeur **négative** dans `rax` (entre `-1` et `-4095`). La valeur absolue correspond au numéro d'erreur (`EBADF`, `EFAULT`…).

---

### La gestion de errno

La variable globale `errno` est utilisée par la libc pour signaler les erreurs des fonctions système. En assembleur, après un syscall en erreur :

1. Le kernel retourne une valeur négative dans `rax` (ex: `-9` pour `EBADF`)
2. Il faut détecter l'erreur (`jnc` / vérifier si `rax` est négatif)
3. Obtenir l'adresse de `errno` via un appel externe
4. Y écrire la valeur positive de l'erreur
5. Retourner `-1` dans `rax`

**Sur Linux**, on appelle `__errno_location` (fonction de la libc) :
```nasm
extern __errno_location   ; déclarer l'externe

; après un syscall en erreur (rax négatif) :
neg     rax               ; rax = code d'erreur positif
push    rax               ; sauvegarder (call peut clobber rax)
call    __errno_location wrt ..plt  ; rax = adresse de errno
pop     rcx
mov     [rax], ecx        ; *errno = code d'erreur
mov     rax, -1           ; retourner -1
```

**Sur macOS**, on appelle `___error` à la place de `__errno_location`.

Le `wrt ..plt` est nécessaire en code **PIC** (Position Independent Code) pour appeler des fonctions externes via la **PLT** (Procedure Linkage Table).

---

### Le flag `-fPIC` et la position indépendante du code

L'interdiction de `-no-pie` signifie que le code **doit être compilable en PIE** (Position Independent Executable). En pratique :

- Les adresses absolues sont interdites pour les symboles externes
- Les appels à des fonctions externes doivent passer par la **PLT** : `call malloc wrt ..plt`
- Les accès à des données globales externes passent par la **GOT** : `mov rax, [rel errno wrt ..got]`

```nasm
; Appel correct d'une fonction externe en PIC
call    malloc wrt ..plt

; Incorrect en PIC (adresse absolue)
call    malloc
```

---

## Structure d'un fichier `.s` NASM

```nasm
; ============================================================
; ft_strlen.s — implémentation de strlen en assembleur NASM
; ============================================================

section .text               ; section contenant le code exécutable

global ft_strlen            ; rendre le symbole visible à l'éditeur de liens

ft_strlen:
    xor     rax, rax        ; rax = 0 (compteur)
    test    rdi, rdi        ; vérifier si le pointeur est NULL
    jz      .end            ; si NULL, sauter à la fin

.loop:
    cmp     byte [rdi + rax], 0   ; comparer le caractère courant à '\0'
    je      .end                  ; si '\0', fin
    inc     rax                   ; incrémenter le compteur
    jmp     .loop                 ; reboucler

.end:
    ret                     ; retourner rax (la longueur)
```

**Directives importantes :**
- `section .text` — code exécutable
- `section .data` — données initialisées
- `section .bss` — données non initialisées (zéro au démarrage)
- `global` — exporter un symbole (nécessaire pour que le linker le voie)
- `extern` — déclarer un symbole défini ailleurs (ex: `malloc`, `__errno_location`)

**Labels locaux :** Un label commençant par `.` (ex: `.loop`) est local à la fonction précédente — bonne pratique pour éviter les conflits de noms.

---

## Instructions essentielles

### Transfert de données

| Instruction | Effet |
|:--|:--|
| `mov dst, src` | `dst = src` |
| `movzx dst, src` | Move avec zero-extension (petite vers grande taille) |
| `movsx dst, src` | Move avec sign-extension |
| `lea dst, [addr]` | Load Effective Address — calcul d'adresse sans déréférencement |
| `push reg` | Empiler `reg` sur la stack (`rsp -= 8`, `[rsp] = reg`) |
| `pop reg` | Dépiler de la stack (`reg = [rsp]`, `rsp += 8`) |
| `xchg a, b` | Échanger les valeurs |

### Arithmétique et logique

| Instruction | Effet |
|:--|:--|
| `add dst, src` | `dst = dst + src` |
| `sub dst, src` | `dst = dst - src` |
| `inc reg` | `reg++` |
| `dec reg` | `reg--` |
| `neg reg` | `reg = -reg` (complément à deux) |
| `and dst, src` | ET logique |
| `or dst, src` | OU logique |
| `xor dst, src` | XOR — `xor rax, rax` est le moyen le plus rapide de mettre un registre à 0 |
| `not reg` | Complément bit à bit |
| `imul dst, src` | Multiplication signée |
| `idiv src` | Division signée (divise `rdx:rax` par `src`) |

### Comparaison et sauts

| Instruction | Effet |
|:--|:--|
| `cmp a, b` | Calcule `a - b` et met à jour les flags (sans stocker le résultat) |
| `test a, b` | Calcule `a AND b` et met à jour les flags |
| `jmp label` | Saut inconditionnel |
| `je / jz` | Jump if Equal / Zero (ZF=1) |
| `jne / jnz` | Jump if Not Equal / Not Zero |
| `jl / jnge` | Jump if Less (signé) |
| `jg / jnle` | Jump if Greater (signé) |
| `jle` | Jump if Less or Equal |
| `jge` | Jump if Greater or Equal |
| `jb / jnae` | Jump if Below (non signé) |
| `ja / jnbe` | Jump if Above (non signé) |
| `js` | Jump if Sign (SF=1, résultat négatif) |
| `jns` | Jump if Not Sign |

### Appels de fonctions

| Instruction | Effet |
|:--|:--|
| `call label` | Empile l'adresse de retour et saute à `label` |
| `ret` | Dépile l'adresse de retour et y saute |
| `syscall` | Appel système (Linux x86-64) |

### Opérations sur la mémoire

```nasm
; Tailles des opérandes en mémoire :
mov byte  [rdi], al      ; 1 octet
mov word  [rdi], ax      ; 2 octets
mov dword [rdi], eax     ; 4 octets
mov qword [rdi], rax     ; 8 octets

; Adressage indexé :
mov al, [rdi + rax]      ; lecture à l'adresse rdi + rax
mov [rdi + rcx*8], rax   ; écriture avec scale (1, 2, 4 ou 8)
```

---

## Fonctions implémentées

### Partie obligatoire

---

#### `ft_strlen`
**Prototype :** `size_t ft_strlen(const char *s)`

Parcourt la chaîne caractère par caractère jusqu'au `\0` et retourne le nombre de caractères.

**Logique clé :** Incrémenter un compteur tant que `[rdi + compteur] != 0`.

---

#### `ft_strcpy`
**Prototype :** `char *ft_strcpy(char *dst, const char *src)`

Copie chaque octet de `src` vers `dst` y compris le `\0` final. Retourne `dst` (valeur initiale de `rdi`).

**Logique clé :** Sauvegarder `rdi` dans un registre callee-saved (ou sur la pile), copier octet par octet jusqu'au `\0` inclus, retourner l'adresse de départ de `dst`.

---

#### `ft_strcmp`
**Prototype :** `int ft_strcmp(const char *s1, const char *s2)`

Compare deux chaînes octet par octet. Retourne :
- `0` si elles sont identiques
- une valeur **négative** si `s1 < s2`
- une valeur **positive** si `s1 > s2`

**Logique clé :** Comparer `[rdi]` et `[rsi]`, si différents retourner `[rdi] - [rsi]` (avec `movzx` pour éviter les problèmes de signe), sinon avancer et reboucler jusqu'au `\0`.

---

#### `ft_write`
**Prototype :** `ssize_t ft_write(int fd, const void *buf, size_t count)`

Wrapper autour du syscall `write` (numéro `1`). Les arguments sont déjà dans les bons registres (`rdi`, `rsi`, `rdx`). Après le `syscall`, gérer les erreurs.

```nasm
ft_write:
    mov     rax, 1          ; syscall write
    syscall
    test    rax, rax
    js      .error          ; si rax < 0 → erreur
    ret

.error:
    neg     rax
    push    rax
    call    __errno_location wrt ..plt
    pop     rcx
    mov     [rax], ecx
    mov     rax, -1
    ret
```

---

#### `ft_read`
**Prototype :** `ssize_t ft_read(int fd, void *buf, size_t count)`

Wrapper autour du syscall `read` (numéro `0`). Même logique de gestion d'erreur que `ft_write`.

---

#### `ft_strdup`
**Prototype :** `char *ft_strdup(const char *s)`

Alloue (`malloc`) un nouveau buffer, y copie la chaîne source, et retourne le pointeur. Retourne `NULL` si `malloc` échoue.

**Logique clé :**
1. Appeler `ft_strlen` (ou recalculer) pour obtenir la taille
2. Appeler `malloc(len + 1)` — via PLT : `call malloc wrt ..plt`
3. Si `rax == 0` → retourner `NULL`
4. Copier la chaîne dans le buffer alloué
5. Retourner le pointeur vers le nouveau buffer

> Penser à sauvegarder les registres callee-saved autour des `call` car `malloc` peut modifier `rax`, `rcx`, `rdx`, etc.

---

### Partie bonus

Les fonctions bonus manipulent une liste chaînée dont la structure est :

```c
typedef struct s_list
{
    void            *data;
    struct s_list   *next;
} t_list;
```

En mémoire, chaque nœud occupe **16 octets** : `data` à l'offset `0`, `next` à l'offset `8`.

---

#### `ft_atoi_base`
**Prototype :** `int ft_atoi_base(char *str, char *base)`

Convertit une chaîne `str` en entier en utilisant la base `base`. Retourne `0` si la base est invalide (vide, un seul caractère, contient des doublons, `+`, `-`, ou espaces blancs).

**Logique :**
1. Valider la base (longueur ≥ 2, pas de `+`/`-`/whitespace, pas de doublons)
2. Skiper les espaces et gérer le signe dans `str`
3. Pour chaque caractère de `str`, trouver son index dans `base`
4. Accumuler : `result = result * base_len + index`

---

#### `ft_list_push_front`
**Prototype :** `void ft_list_push_front(t_list **begin_list, void *data)`

Alloue un nouveau nœud, lui assigne `data`, le fait pointer vers l'ancien premier élément, puis met à jour `*begin_list`.

**Accès mémoire en ASM :**
```nasm
; Nouveau nœud dans rax (retour de malloc)
mov     [rax], rsi          ; nœud->data = data (rsi = 2ème arg)
mov     rcx, [rdi]          ; rcx = *begin_list (ancien head)
mov     [rax + 8], rcx      ; nœud->next = ancien head
mov     [rdi], rax          ; *begin_list = nouveau nœud
```

---

#### `ft_list_size`
**Prototype :** `int ft_list_size(t_list *begin_list)`

Parcourt la liste en suivant les pointeurs `next` (offset `+8`) jusqu'à `NULL`, en incrémentant un compteur.

---

#### `ft_list_sort`
**Prototype :** `void ft_list_sort(t_list **begin_list, int (*cmp)())`

Trie la liste en ordre croissant via un algorithme de type **bubble sort** : parcourir la liste, comparer deux nœuds adjacents avec `(*cmp)(a->data, b->data)`, échanger leurs `data` si nécessaire, répéter jusqu'à ce que la liste soit triée.

> Note : on échange les `data` (les pointeurs `void *`), pas les nœuds entiers — c'est plus simple en ASM.

**Appel de fonction via pointeur :**
```nasm
; rcx = pointeur vers la fonction cmp
; rdi et rsi = les deux data à comparer
call    rcx                 ; appel indirect via registre
```

---

#### `ft_list_remove_if`
**Prototype :** `void ft_list_remove_if(t_list **begin_list, void *data_ref, int (*cmp)(), void (*free_fct)(void *))`

Parcourt la liste, et pour chaque nœud où `cmp(nœud->data, data_ref) == 0`, libère `data` avec `free_fct`, puis libère le nœud avec `free`, et relie le nœud précédent au nœud suivant.

**Cas à gérer :** le premier nœud peut être supprimé (mettre à jour `*begin_list`).

---

## Makefile

```makefile
NAME = libasm.a
COMPILER = nasm
FORMAT = elf64
RM = rm -rf
AR = ar rcs

SRCS =  mandatory_part/ft_strlen.s \
        mandatory_part/ft_read.s \
        mandatory_part/ft_strcmp.s \
        mandatory_part/ft_strcpy.s \
        mandatory_part/ft_write.s \
        mandatory_part/ft_strdup.s \
		mandatory_part/ft_putstr.s

SRCS_BONUS =	bonus_part/ft_list_push_front.s \
				bonus_part/ft_list_size.s \
				bonus_part/ft_list_sort.s \
				bonus_part/ft_list_remove_if.s \
				bonus_part/ft_atoi_base.s

OBJS = $(SRCS:.s=.o)
OBJS_BONUS = $(SRCS_BONUS:.s=.o)

RED     := \033[31m
YELLOW  := \033[33m
GREEN   := \033[32m
BLUE    := \033[34m
RESET   := \033[0m

all: $(NAME)

$(NAME): $(OBJS)
	@echo "$(BLUE)Creating $(NAME)...$(RESET)"
	@$(AR) $(NAME) $(OBJS)

%.o: %.s
	@echo "$(GREEN)Compiling $<$(RESET)"
	@$(COMPILER) -f $(FORMAT) $< -o $@

clean:
	@echo "$(BLUE)Cleaning objects...$(RESET)"
	@$(RM) $(OBJS) $(OBJS_BONUS)

fclean: clean
	@echo "$(BLUE)Removing $(NAME)...$(RESET)"
	@$(RM) $(NAME)

re: fclean all

bonus: $(OBJS) $(OBJS_BONUS)
	@echo "$(BLUE)Creating with bonus $(NAME)...$(RESET)"
	@$(AR) $(NAME) $(OBJS) $(OBJS_BONUS)

.PHONY: all clean fclean re bonus
```

> Le flag `-f elf64` indique à NASM de produire un objet ELF 64-bit (format Linux).

---

## Conseils & pièges courants

**1. Toujours `xor rax, rax` pour mettre rax à 0**
`xor rax, rax` est plus court et plus rapide que `mov rax, 0`.

**2. Faire attention aux tailles de registres**
`cmp byte [rdi], 0` compare un octet. Sans `byte`, NASM peut se plaindre ou utiliser la mauvaise taille.

**3. Sauvegarder les callee-saved avant tout `call`**
Si vous utilisez `rbx`, `r12`, etc. dans votre fonction, sauvegardez-les avec `push`/`pop` en prologue/épilogue.

**4. Aligner la pile avant un `call`**
Si vous faites un `call` à l'intérieur d'une fonction, `rsp` doit être aligné sur 16 octets au moment du `call`. Calculez l'alignement selon votre nombre de `push`.

**5. `wrt ..plt` pour les appels externes**
Sans `-no-pie`, tout appel à une fonction externe (`malloc`, `__errno_location`, `free`…) doit utiliser `call fonction wrt ..plt`.

**6. Tester le retour de `syscall` avec `js` ou comparer à 0**
Un syscall en erreur retourne une valeur entre `-1` et `-4095`. `js .error` saute si le bit de signe est mis (valeur négative).

**7. Les labels locaux évitent les conflits**
Utilisez `.loop`, `.end`, `.error` (avec le point) pour les labels internes à une fonction — ils sont scoped à la dernière étiquette globale.

**8. `movzx` pour les comparaisons de char**
Un `char` est 8-bit. Pour faire des opérations arithmétiques ou des comparaisons propres, utilisez `movzx eax, byte [rdi]` pour étendre sans signe vers 32-bit.

**9. Tester avec valgrind**
Compiler votre `main.c` de test avec la lib : `gcc main.c -L. -lasm -o test` puis `valgrind ./test` pour détecter les fuites mémoire dans `ft_strdup` ou les bonus.

**10. macOS vs Linux**
- Linux : `extern __errno_location`
- macOS : `extern ___error` (trois underscores)
- Les numéros de syscalls diffèrent aussi — attention si vous portez votre code.

---

## Récapitulatif des connaissances acquises

| Domaine | Ce qu'on apprend |
|:--|:--|
| Architecture x86-64 | Registres, tailles, rôles |
| Calling convention | Passage d'arguments, valeur de retour, registres sauvegardés |
| Assembleur NASM | Syntaxe Intel, directives, labels, sections |
| Mémoire | Adressage indirect, offsets, déréférencement |
| Syscalls Linux | Interface kernel, numéros, convention différente de ABI |
| Gestion d'erreurs | errno, PLT, GOT, code PIC |
| Linked lists en ASM | Manipulation de structures via offsets mémoire |
| Fonctions callback | Appel indirect via pointeur de fonction en registre |
| Makefile | Compilation d'ASM, création de bibliothèque statique `.a` |