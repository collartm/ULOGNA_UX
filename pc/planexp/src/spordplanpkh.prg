/* $Id$
****************************************************************************
* sp_ord_plan_pkg - Calcul de l'ordre des UEE
*/
-- DESCRIPTION :
-- -------------
-- Ce package permet de calculer l'ordre des UEE pour faire des couches "mono-hauteur"
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01a,19.06.14,tcho    Création
-- 00a,12.01.10,GENPRG  version 2.13
-- -------------------------------------------------------------------------
--

CREATE OR REPLACE
PACKAGE sp_ord_plan_pkg AS

    TYPE tt_ord IS TABLE OF integer INDEX BY VARCHAR2(30);

    vt_ord tt_ord;

    g_cle timestamp;

    function uee_exists(p_no_uee varchar2) return integer;
    FUNCTION su_bas_tab_get_ord(
    p_no_uee        pc_uee.no_uee%TYPE,
    p_no_session    number,
    p_cod_up        pc_up.cod_up%TYPE,
    p_cle           timestamp     -- toujours mettre systimestamp
    )
    return integer;


END;
/
show errors;

