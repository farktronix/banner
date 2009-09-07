#import <Foundation/Foundation.h>

#define kDictPath "/usr/share/dict/propernames"
#define kMaxWord 256

typedef struct _trie *trie;

struct _trie {
	char valid;
	trie letter[26];
	int count;
	
	int depth;
	trie parent;
};

void addWord(trie root, char *word)
{
	int i, count = strlen(word);
	for (i = 0; i < count; i++) {
		int charVal = (int)(tolower(*(word + i)) - 'a');
		if (root->letter[charVal] == 0) {
			root->letter[charVal] = (trie)calloc(1, sizeof(struct _trie));
		}
		root->count++;
		root = root->letter[charVal];
	}
	root->valid = 1;
}
		
void printTrie(trie root, char buf[kMaxWord])
{
	int i;
	int wordLen = strlen(buf);
	if (root->valid == 1) printf("%s\n", buf);
	for (i = 0; i < 26; i++) {
		if (root->letter[i] != 0) {
			buf[wordLen] = 'a' + i;
			printTrie(root->letter[i], buf);
		}
	}
	buf[wordLen] = '\0';
}

int buildDictTrie(trie root, int minLen)
{
	char buf[kMaxWord] = {0};
	
	FILE *dict = fopen(kDictPath, "r");
	if (!dict) {
		printf("Couldn't open dictionary at %s: %s\n", kDictPath, strerror(errno));
		return 1;
	}
	
	while (fgets(buf, kMaxWord, dict) != NULL) {
		int len = strlen(buf);
		if (len < minLen) continue;
		buf[len - 1] = '\0'; // chomp the newline
		addWord(root, buf);
		memset(buf, '\0', kMaxWord);
	}
	
	fclose(dict);
	
	return 0;
}

char *randword(trie root)
{
	if (root == NULL) return NULL;
	char *buf = calloc(1, kMaxWord);
	int i, wordLen = 0;
	do {
		i = rand() % 27;
		if (i == 26) {
			if (root->valid) break;
			else continue;
		}
		if (root->letter[i] == NULL) continue;
		
		buf[wordLen++] = 'a' + i;
		root = root->letter[i];
	} while (root);
	return buf;
}

char *bestSubword(trie dict, char *word, int *subLen)
{
	char *buf = calloc(1, kMaxWord);
	int len = strlen(word);
	int i;
	for (i = len / 3; i < len; i++) {
		int j;
		trie subdict = dict;
		for (j = i; j < len && subdict; j++) {
			int charVal = (int)(tolower(*(word + j)) - 'a');
			subdict = subdict->letter[charVal];
		}
		if (subdict && j == len) {
			strncpy(buf, word + i, len - i);
			char *rnd = randword(subdict);
			strncpy(buf + (len - i), rnd, strlen(rnd));
			*subLen = len - i;
			free(rnd);
			break;
		}
	}
	
	return buf;
}

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	struct _trie root = {0};
	srand(time(0));
	
	buildDictTrie(&root, 4);
	
//	printf("Total entries: %d\n", root.count);
	
	char longName[2048] = {0};
	char *ln = longName;
	char * rndWrd = randword(&root);
	printf("%s(%d).", rndWrd, 0);
	sprintf(ln, "%s", rndWrd);
	ln += strlen(rndWrd);
	int i;
	for (i = 0; i < 10; i++) {
		int subLen = 0;
		char *newWord = bestSubword(&root, rndWrd, &subLen);
		printf("%s(%d).", newWord, subLen);
		sprintf(ln, "%s", newWord + subLen);
		ln += strlen(newWord + subLen);
		
		free(rndWrd);
		rndWrd = newWord;
	}
	printf("\n%s\n", longName);
//	printf("Here is a random word for you: %s / %s\n", rndWord, subWord);
	
    [pool drain];
    return 0;
}
