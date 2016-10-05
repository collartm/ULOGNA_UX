CREATE OR REPLACE PACKAGE sp_stat_pkg AS
    TYPE tr_debit IS RECORD(date_trait  DATE,
                            debit       NUMBER,
                            total       NUMBER);

    TYPE tt_debit IS TABLE OF tr_debit;   
    

    ------------------------------------------------------------------------------
    -- d�bit � partir du nombre d'�l�ments
    ------------------------------------------------------------------------------
    FUNCTION debit_count(p_table          VARCHAR2,
                         p_col_time   VARCHAR,
                         p_nb_int     NUMBER,
                         p_jour       DATE,
                         p_hmin       number,
                         p_hmax       number,
                         p_where      VARCHAR2 DEFAULT NULL) RETURN tt_debit PIPELINED;

    ------------------------------------------------------------------------------
    -- d�bit � partir de la somme ou la moynne d'�l�ments
    ------------------------------------------------------------------------------
    FUNCTION debit_nombre_sum(p_table          VARCHAR2,
                              p_col_time       VARCHAR,
                              p_col_sum        VARCHAR2,
                              p_nb_int         NUMBER,
                              p_jour           DATE,
                              p_hmin           number,
                              p_hmax           number,
                              p_where          VARCHAR2 DEFAULT NULL) RETURN tt_debit PIPELINED;

    ------------------------------------------------------------------------------
    -- d�bit � partir d'un d�bit theorique
    ------------------------------------------------------------------------------
    FUNCTION debit_debit(p_table          VARCHAR2,
                         p_col_time       VARCHAR,
                         p_col_debit      VARCHAR2,
                         p_nb_int         NUMBER,
                         p_jour           DATE,
                         p_hmin           number,
                         p_hmax           number,
                         p_where          VARCHAR2 DEFAULT NULL) RETURN tt_debit PIPELINED;
                         
    ------------------------------------------------------------------------------
    -- d�bit � partir d'une fonction d'agregat
    ------------------------------------------------------------------------------
    FUNCTION debit_agg_exp(p_table          VARCHAR2,
                           p_col_time       VARCHAR,
                           p_agg_exp        VARCHAR2,
                           p_nb_int         NUMBER,
                           p_jour           DATE,
                           p_hmin           number,
                           p_hmax           number,
                           p_where          VARCHAR2 DEFAULT NULL) RETURN tt_debit PIPELINED;
                           
     FUNCTION qte_plage_date(p_table          VARCHAR2,
                           p_col_time       VARCHAR,
                           p_col_time_2     VARCHAR,
                           p_jour           DATE,
                           p_hmin           number,
                           p_hmax           number,
                           p_where          VARCHAR2,
                           p_col_qte        VARCHAR2 DEFAULT '1') RETURN tt_debit PIPELINED;
                           
     FUNCTION qte_plage_date_sec(p_table          VARCHAR2,
                           p_col_time       VARCHAR,
                           p_col_time_2     VARCHAR,
                           p_jour           DATE,
                           p_hmin           number,
                           p_hmax           number,
                           p_where          VARCHAR2,
                           p_col_qte        VARCHAR2 DEFAULT '1') RETURN tt_debit PIPELINED;
END;
/
show errors;