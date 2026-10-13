import datetime
import decimal
from typing import Optional

from sqlalchemy import (
    DECIMAL,
    Boolean,
    Date,
    ForeignKeyConstraint,
    Identity,
    Index,
    Integer,
    PrimaryKeyConstraint,
    String,
    Unicode,
    text,
)
from sqlalchemy.dialects.mssql import DATETIME2
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    pass


class Categorie(Base):
    __tablename__ = 'categorie'
    __table_args__ = (
        PrimaryKeyConstraint('categorie_id', name='PK__categori__55E5113F53499E97'),
    )

    categorie_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    nom: Mapped[str] = mapped_column(Unicode(50, 'SQL_Latin1_General_CP1_CI_AS'), nullable=False)

    produit: Mapped[list['Produit']] = relationship('Produit', back_populates='categorie')


class Client(Base):
    __tablename__ = 'client'
    __table_args__ = (
        PrimaryKeyConstraint('client_id', name='PK__client__BF21A4246BC21255'),
    )

    client_id: Mapped[int] = mapped_column(Integer, Identity(start=1, increment=1), primary_key=True, autoincrement=True)
    nom: Mapped[str] = mapped_column(Unicode(50, 'SQL_Latin1_General_CP1_CI_AS'), nullable=False)
    prenom: Mapped[str] = mapped_column(Unicode(50, 'SQL_Latin1_General_CP1_CI_AS'), nullable=False)
    date_inscription: Mapped[datetime.date] = mapped_column(Date, nullable=False)
    email: Mapped[str | None] = mapped_column(Unicode(150, 'SQL_Latin1_General_CP1_CI_AS'))
    date_naissance: Mapped[datetime.date | None] = mapped_column(Date)
    code_postal: Mapped[str | None] = mapped_column(String(10, 'SQL_Latin1_General_CP1_CI_AS'))

    commande: Mapped[list['Commande']] = relationship('Commande', back_populates='client')


class Magasin(Base):
    __tablename__ = 'magasin'
    __table_args__ = (
        PrimaryKeyConstraint('magasin_id', name='PK__magasin__F85364722AFAE916'),
    )

    magasin_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    nom: Mapped[str] = mapped_column(Unicode(100, 'SQL_Latin1_General_CP1_CI_AS'), nullable=False)
    adresse: Mapped[str] = mapped_column(Unicode(200, 'SQL_Latin1_General_CP1_CI_AS'), nullable=False)
    ville: Mapped[str] = mapped_column(Unicode(100, 'SQL_Latin1_General_CP1_CI_AS'), nullable=False)
    pays: Mapped[str] = mapped_column(Unicode(50, 'SQL_Latin1_General_CP1_CI_AS'), nullable=False)
    date_ouverture: Mapped[datetime.date] = mapped_column(Date, nullable=False)
    actif: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('((1))'))
    code_postal: Mapped[str | None] = mapped_column(String(10, 'SQL_Latin1_General_CP1_CI_AS'))

    commande: Mapped[list['Commande']] = relationship('Commande', back_populates='magasin')


class Commande(Base):
    __tablename__ = 'commande'
    __table_args__ = (
        ForeignKeyConstraint(['client_id'], ['client.client_id'], name='FK__commande__client__440B1D61'),
        ForeignKeyConstraint(['magasin_id'], ['magasin.magasin_id'], name='FK__commande__magasi__4316F928'),
        PrimaryKeyConstraint('commande_id', name='PK__commande__AF8DE0448522A7A8')
    )

    commande_id: Mapped[int] = mapped_column(Integer, Identity(start=1, increment=1), primary_key=True, autoincrement=True)
    magasin_id: Mapped[int] = mapped_column(Integer, nullable=False)
    date_commande: Mapped[datetime.datetime] = mapped_column(DATETIME2, nullable=False)
    statut: Mapped[str] = mapped_column(String(10, 'SQL_Latin1_General_CP1_CI_AS'), nullable=False)
    mode_paiement: Mapped[str] = mapped_column(String(10, 'SQL_Latin1_General_CP1_CI_AS'), nullable=False)
    client_id: Mapped[int | None] = mapped_column(Integer)

    client: Mapped[Optional['Client']] = relationship('Client', back_populates='commande')
    magasin: Mapped['Magasin'] = relationship('Magasin', back_populates='commande')
    ligne_commande: Mapped[list['LigneCommande']] = relationship('LigneCommande', back_populates='commande')


class Produit(Base):
    __tablename__ = 'produit'
    __table_args__ = (
        ForeignKeyConstraint(['categorie_id'], ['categorie.categorie_id'], name='FK__produit__categor__3A81B327'),
        PrimaryKeyConstraint('produit_id', name='PK__produit__59863B49B9ECBED4'),
        Index('UQ__produit__357D4CF949208496', 'code', mssql_clustered=False, unique=True)
    )

    produit_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    code: Mapped[str] = mapped_column(String(10, 'SQL_Latin1_General_CP1_CI_AS'), nullable=False)
    nom: Mapped[str] = mapped_column(Unicode(100, 'SQL_Latin1_General_CP1_CI_AS'), nullable=False)
    prix_unitaire: Mapped[decimal.Decimal] = mapped_column(DECIMAL(6, 2), nullable=False)
    actif: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('((1))'))
    categorie_id: Mapped[int | None] = mapped_column(Integer)

    categorie: Mapped[Optional['Categorie']] = relationship('Categorie', back_populates='produit')
    ligne_commande: Mapped[list['LigneCommande']] = relationship('LigneCommande', back_populates='produit')


class LigneCommande(Base):
    __tablename__ = 'ligne_commande'
    __table_args__ = (
        ForeignKeyConstraint(['commande_id'], ['commande.commande_id'], name='FK__ligne_com__comma__47DBAE45'),
        ForeignKeyConstraint(['produit_id'], ['produit.produit_id'], name='FK__ligne_com__produ__48CFD27E'),
        PrimaryKeyConstraint('ligne_id', name='PK__ligne_co__CA8432CC11889E96')
    )

    ligne_id: Mapped[int] = mapped_column(Integer, Identity(start=1, increment=1), primary_key=True, autoincrement=True)
    commande_id: Mapped[int] = mapped_column(Integer, nullable=False)
    produit_id: Mapped[int] = mapped_column(Integer, nullable=False)
    quantite: Mapped[int] = mapped_column(Integer, nullable=False)
    prix_unitaire: Mapped[decimal.Decimal] = mapped_column(DECIMAL(6, 2), nullable=False)
    remise_pct: Mapped[decimal.Decimal] = mapped_column(DECIMAL(5, 2), nullable=False, server_default=text('((0))'))

    commande: Mapped['Commande'] = relationship('Commande', back_populates='ligne_commande')
    produit: Mapped['Produit'] = relationship('Produit', back_populates='ligne_commande')
