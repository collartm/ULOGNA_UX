/* $Id$
****************************************************************************
* sp_stat_reg_sqc_pkv - 
*/
-- DESCRIPTION :
-- -------------
-- Ce package gère une vue table pour statistique sur regulation/préparation palette
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 
-- 01a,04.06.15,rbel    Création
-- 00a,20.01.11,GENPRG  version 2.13
-- -------------------------------------------------------------------------
--

CREATE OR REPLACE
PACKAGE sp_stat_reg_sqc_pkv AS

    -- Record entete                          
    TYPE tr_stat_reg_sqc IS RECORD
    (
         NO_UEE    VARCHAR2 (21),
         COD_OPS   VARCHAR2 (20),
         NO_COM    VARCHAR2 (20),
         DAT_CREA_COM DATE ,
         DAT_EXP      DATE,
         COD_UT_SUP   VARCHAR2 (20),
         NO_UEE_UT_P1 NUMBER,
         DAT_ORDO     DATE,
         DAT_REG_ENT_SQC DATE,
         NO_SQC          NUMBER (10),
         DAT_SORTIE_FLEXY DATE,
         DAT_TIR_RP_ENT_SQC DATE,
         DAT_ENT_SQC        DATE,
         DAT_REG_SOR_SQC    DATE,
         DAT_SOR_SQC        DATE,
         DAT_TIR_ROBOT      DATE,
         DAT_DER_TIR_ROBOT  DATE,
         REF_TRF_1          VARCHAR2 (30),
         COD_EMP_FLEXY      VARCHAR2 (20),
         FLEXY              VARCHAR2 (10),
         COD_EMP_SQC        VARCHAR2 (20),
         ASCENSEUR_SQC      VARCHAR2 (4000),
         NO_SQM             VARCHAR2 (30),
         NO_ORD_SQM         VARCHAR2 (30),
         DAT_CREA_ORD_SORTIE_FLEXY DATE,
         NB_UT_UTILISE      NUMBER);
        
    TYPE tt_stat_reg_sqc IS TABLE OF tr_stat_reg_sqc;
    
END;
/
show errors;