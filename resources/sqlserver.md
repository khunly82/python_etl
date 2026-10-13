# Prerequis

1. Installer pyodbc et sqlalchemy

```sh
pip install sqlalchemy pyodbc
```

## Sur Jupyter
```sh
%pip install sqlalchemy pyodbc
```


# Se connecter

2. Créer la connection

```python
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# mssql+pyodbc://username:password@localhost:1433/nom_de_la_db
url_connection = "mssql+pyodbc://sa:test1234=@localhost:1433/dbslide"
url_connection += "?driver=ODBC+Driver+17+for+SQL+Server"

# création du moteur de connection à SQL server
engine = create_engine(url=url_connection)

# créer une usine à session
session_factory = sessionmaker(bind=engine)
```

# Création des modeles (classes)

```python
from datetime import date

from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship
from sqlalchemy import ForeignKey


class Base(DeclarativeBase):
    pass

class Student(Base):
    __tablename__ = "student"

    student_id: Mapped[int] = mapped_column(primary_key=True)
    last_name: Mapped[str] = mapped_column()
    first_name: Mapped[str] = mapped_column()
    birth_date: Mapped[date] = mapped_column()
    login: Mapped[str] = mapped_column()
    year_result: Mapped[int] = mapped_column()
    section_id: Mapped[int] = mapped_column(ForeignKey("section.section_id"))
    course_id: Mapped[str] = mapped_column()

    section: Mapped["Section"] = relationship()

class Section(Base):
    __tablename__ = "section"
    section_id: Mapped[int] = mapped_column(primary_key=True, autoincrement=False)
    section_name: Mapped[str] = mapped_column()

    students: Mapped[list["Student"]] = relationship()
```

# Récupérer des données

```python
from sqlalchemy import select

with sesssion_factory() as session:
    query = select(Student).where(Student.year_result > 12).orderby(Student.year_result)
    
    # pour récupérer la liste
    data = session.execute(query).scalars().all() 
    
    # pour récupérer le premier de la liste
    data = session.execute(query).scalars().one_or_none() 
```

# Insérer une nouvelle ligne

```python
with session_factory() as session:
    s = Student() # création d'un instance de Student
    # modification des données de l'etudiant

    s.student_id = 99
    s.last_name = "LY"
    s.first_name = "Khun"
    s.year_result = 5
    s.section_id = 1110
    s.course_id = ""
    s.birth_date = date(1982, 5, 6)

    # sauvegarde
    session.add(s)
    session.commit()
```

# Jointure


## Lazy loading
chargement des données en fonction des besoins (peut parfois être plus lent)

```python
with session_factory() as session:
    query = select(Section)
    data = session.scalars(query).all()

    for sec in data:
        print(sec.section_name)
        for std in sec.students:
            print(std.last_name, std.first_name)
        print('--------------')

```

## Eager loading
chargement des données avec jointure explicite

```python
from sqlalchemy.orm import joinloaded

with session_factory() as session:
    query = select(Section).options(joinloaded(Section.students))
    data = session.scalars(query).all()

    for sec in data:
        print(sec.section_name)
        for std in sec.students:
            print(std.last_name, std.first_name)
        print('--------------')

```