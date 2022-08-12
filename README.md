![Java 17](https://img.shields.io/badge/java-%23ED8B00.svg?logo=java&logoColor=white)
![Spring](https://img.shields.io/badge/spring-%236DB33F.svg?logo=spring&logoColor=white)
![Coverage](coverage-badge.svg)

## Preparazione ambiente sviluppo
L'applicazione funziona all'interno di un container docker. Preparare l'ambiente in questo modo:

#### Clone del progetto

```bash
git clone git@github.com:repo/repo.git
make prepare && make up
```


## Test Suite

##### Per lanciare il testsuite:
```bash
make test
```

## Code Coverage
```bash
make coverage
```
