CREATE OR REPLACE PACKAGE BODY sp_stat_pkg AS
    TYPE tt_nb IS TABLE OF PLS_INTEGER INDEX BY PLS_INTEGER;   
    TYPE tt_debit2 IS TABLE OF tr_debit INDEX BY PLS_INTEGER;

    ------------------------------------------------------------------------------
    -- initialise un tablea qui a comme position HH24MI et comme valeur 0 
    ------------------------------------------------------------------------------
    PROCEDURE init_tt_nb(p_tt_nb IN OUT NOCOPY tt_nb, p_hmin NUMBER, p_hmax NUMBER) IS
        i       pls_integer;
        j       pls_integer;
        i100    pls_integer;
    BEGIN
        p_tt_nb.delete;
        
        FOR i IN p_hmin .. p_hmax-1 LOOP
            i100 := i*100;
            
            FOR j IN 0..59 LOOP
                p_tt_nb(i100+j) := 0;                
            END LOOP;
        END LOOP;
    END;
    
    PROCEDURE init_tt_nb_sec(p_tt_nb IN OUT NOCOPY tt_nb, p_hmin NUMBER, p_hmax NUMBER) IS
        i       pls_integer;
        j       pls_integer;
        k       pls_integer;
        heure   pls_integer;
        heuremin pls_integer;
    BEGIN
        p_tt_nb.delete;
        
        FOR i IN p_hmin .. p_hmax-1 LOOP
            heure := i*10000;
            
            FOR j IN 0..59 LOOP
                heuremin := heure + (j*100);
                
                FOR k IN 0..59 LOOP
                    p_tt_nb((heuremin+k)) := 0;                
                END LOOP;
                                
            END LOOP;
        END LOOP;
    END;

    ------------------------------------------------------------------------------
    -- calcule une moyenne du debit horaire sur les n dernieres minutes
    ------------------------------------------------------------------------------
    FUNCTION calc_sum(p_tt_nb tt_nb) RETURN NUMBER IS
        v_pos BINARY_INTEGER;
        v_ret NUMBER := 0;
    BEGIN
        v_pos := p_tt_nb.first;
        
        WHILE v_pos IS NOT NULL LOOP
            v_ret := v_ret + p_tt_nb(v_pos);
                 
            v_pos := p_tt_nb.next(v_pos);
        END LOOP;
        
        RETURN v_ret;
    END;

    ------------------------------------------------------------------------------
    -- calcule une moiene du debit horaire sur les n dernieres minutes
    ------------------------------------------------------------------------------
    FUNCTION calc_debit(p_jour DATE, p_nb_int NUMBER, p_tt_nb tt_nb) RETURN tt_debit2 IS
        v_h1    PLS_INTEGER;
        v_h2    PLS_INTEGER;
        
        v_debit tt_debit2;
        v_sum   NUMBER := 0;
        
        v_total NUMBER := calc_sum(p_tt_nb);
        
        v_count PLS_INTEGER := 0; 
    BEGIN
        v_h1 := p_tt_nb.first;
        v_h2 := p_tt_nb.first;
        
        WHILE v_h2 IS NOT NULL LOOP
            v_sum := v_sum + p_tt_nb(v_h2);
            
            v_debit(v_h2).date_trait    := to_date(to_char(p_jour, 'YYYYMMDD')||lpad(v_h2, 4, 0), 'YYYYMMDDHH24MI');
            v_debit(v_h2).debit         := v_sum * 60 / p_nb_int;
            v_debit(v_h2).total         := v_total;
        
            v_count := v_count + 1;
            
            IF v_count >= p_nb_int THEN
                v_sum := v_sum - p_tt_nb(v_h1);
                v_h1 := p_tt_nb.next(v_h1);
            END IF;            
                
            v_h2 := p_tt_nb.next(v_h2); 
        END LOOP;
        
        RETURN v_debit;
    END; 

    ------------------------------------------------------------------------------
    -- fonction débit générale 
    ------------------------------------------------------------------------------
    FUNCTION debit(p_table          VARCHAR2,
                   p_col_time       VARCHAR,
                   p_agg_exp        VARCHAR2,
                   p_nb_int         NUMBER,
                   p_jour           DATE,
                   p_hmin           number,
                   p_hmax           number,
                   p_where          VARCHAR2) RETURN tt_debit2 IS
         v_hmin NUMBER := least(p_hmin, p_hmax);                                              
         v_hmax NUMBER := greatest(p_hmin, p_hmax);

         type type_ref_cursor IS REF CURSOR; 

         v_cursor   type_ref_cursor;
         v_sql      VARCHAR2(4000);

         v_tt_nb tt_nb;
         
         v_nb_bac NUMBER;
         v_h      NUMBER;
         
         v_debit  tt_debit2;    
         v_pos    pls_integer;   
    BEGIN
         init_tt_nb(v_tt_nb, v_hmin, v_hmax);
         
         v_sql := 'SELECT '||p_agg_exp||', to_number(to_char('||p_col_time||', ''HH24MI'')) h '||
                  'FROM '||p_table||' '|| 
                  'WHERE '||p_col_time||' >= trunc(:p_jour) '|| 
                  'AND '||p_col_time||' < trunc(:p_jour) + 1 '||
                  'AND to_number(to_char('||p_col_time||', ''HH24'')) >= :p_hmin '|| 
                  'AND to_number(to_char('||p_col_time||', ''HH24'')) < :p_hmax ';
                  
         IF p_where IS NOT NULL THEN
            v_sql := v_sql||' AND '||p_where;
         END IF;
                  
         v_sql := v_sql||' group by to_number(to_char('||p_col_time||', ''HH24MI'')) '||
                         'order by h';    
         
         OPEN v_cursor FOR v_sql USING p_jour, p_jour, v_hmin, v_hmax;
         
        LOOP
            FETCH v_cursor INTO v_nb_bac, v_h;
            EXIT WHEN v_cursor%NOTFOUND;

            v_tt_nb(v_h) := v_tt_nb(v_h)+v_nb_bac;  
        END LOOP;         
         
        
        RETURN calc_debit(p_jour, p_nb_int, v_tt_nb);
    END;                                


    ------------------------------------------------------------------------------
    -- débit à partir du nombre d'éléments
    ------------------------------------------------------------------------------
    FUNCTION debit_count(p_table          VARCHAR2,
                         p_col_time   VARCHAR,
                         p_nb_int     NUMBER,
                         p_jour       DATE,
                         p_hmin       number,
                         p_hmax       number,
                         p_where      VARCHAR2 DEFAULT NULL) RETURN tt_debit PIPELINED IS
        v_debit  tt_debit2;    
        v_pos    pls_integer;   
    BEGIN
        v_debit := debit(p_table            => p_table,
                         p_col_time         => p_col_time,
                         p_agg_exp          => 'count(*)',
                         p_nb_int           => p_nb_int,
                         p_jour             => p_jour,
                         p_hmin             => p_hmin,
                         p_hmax             => p_hmax,
                         p_where            => p_where);

        
        v_pos := v_debit.first;
         
        WHILE v_pos IS NOT NULL LOOP
           PIPE ROW(v_debit(v_pos));
           v_pos := v_debit.next(v_pos);
        END LOOP;
    END;
    
    ------------------------------------------------------------------------------
    -- débit à partir de la somme ou la moynne d'éléments
    ------------------------------------------------------------------------------
    FUNCTION debit_nombre_sum(p_table          VARCHAR2,
                              p_col_time       VARCHAR,
                              p_col_sum        VARCHAR2,
                              p_nb_int         NUMBER,
                              p_jour           DATE,
                              p_hmin           number,
                              p_hmax           number,
                              p_where          VARCHAR2 DEFAULT NULL) RETURN tt_debit PIPELINED IS
        v_debit  tt_debit2;    
        v_pos    pls_integer;   
    BEGIN
        v_debit := debit(p_table            => p_table,
                         p_col_time         => p_col_time,
                         p_agg_exp          => 'sum('||p_col_sum||')',
                         p_nb_int           => p_nb_int,
                         p_jour             => p_jour,
                         p_hmin             => p_hmin,
                         p_hmax             => p_hmax,
                         p_where            => p_where);

        
        v_pos := v_debit.first;
         
        WHILE v_pos IS NOT NULL LOOP
           PIPE ROW(v_debit(v_pos));
           v_pos := v_debit.next(v_pos);
        END LOOP;
    END;                              

    ------------------------------------------------------------------------------
    -- débit à partir d'un débit theorique
    ------------------------------------------------------------------------------
    FUNCTION debit_debit(p_table          VARCHAR2,
                         p_col_time       VARCHAR,
                         p_col_debit      VARCHAR2,
                         p_nb_int         NUMBER,
                         p_jour           DATE,
                         p_hmin           number,
                         p_hmax           number,
                         p_where          VARCHAR2 DEFAULT NULL) RETURN tt_debit PIPELINED IS
        v_debit  tt_debit2;    
        v_pos    pls_integer;   
    BEGIN
        v_debit := debit(p_table            => p_table,
                         p_col_time         => p_col_time,
                         p_agg_exp          => 'sum('||p_col_debit||')/60',
                         p_nb_int           => p_nb_int,
                         p_jour             => p_jour,
                         p_hmin             => p_hmin,
                         p_hmax             => p_hmax,
                         p_where            => p_where);

        
        v_pos := v_debit.first;
         
        WHILE v_pos IS NOT NULL LOOP
           PIPE ROW(v_debit(v_pos));
           v_pos := v_debit.next(v_pos);
        END LOOP;
    END;                                  
    
    ------------------------------------------------------------------------------
    -- débit à partir d'une expression d'agrégation
    ------------------------------------------------------------------------------
    FUNCTION debit_agg_exp(p_table          VARCHAR2,
                         p_col_time       VARCHAR,
                         p_agg_exp        VARCHAR2,
                         p_nb_int         NUMBER,
                         p_jour           DATE,
                         p_hmin           number,
                         p_hmax           number,
                         p_where          VARCHAR2 DEFAULT NULL) RETURN tt_debit PIPELINED IS
        v_debit  tt_debit2;    
        v_pos    pls_integer;   
    BEGIN
        v_debit := debit(p_table            => p_table,
                         p_col_time         => p_col_time,
                         p_agg_exp          => p_agg_exp,
                         p_nb_int           => p_nb_int,
                         p_jour             => p_jour,
                         p_hmin             => p_hmin,
                         p_hmax             => p_hmax,
                         p_where            => p_where);

        
        v_pos := v_debit.first;
         
        WHILE v_pos IS NOT NULL LOOP
           PIPE ROW(v_debit(v_pos));
           v_pos := v_debit.next(v_pos);
        END LOOP;
    END;
    
    
    ------------------------------------------------------------------------------
    -- fonction débit générale 
    ------------------------------------------------------------------------------
    FUNCTION qte_plage_date(p_table         VARCHAR2,
                           p_col_time       VARCHAR,
                           p_col_time_2     VARCHAR,
                           p_jour           DATE,
                           p_hmin           number,
                           p_hmax           number,
                           p_where          VARCHAR2,
                           p_col_qte        VARCHAR2 DEFAULT '1') RETURN tt_debit PIPELINED IS
         v_hmin NUMBER := least(NVL(p_hmin,0), NVL(p_hmax,24));                                              
         v_hmax NUMBER := greatest(NVL(p_hmin,0), NVL(p_hmax,24));

         type type_ref_cursor IS REF CURSOR; 

         v_cursor   type_ref_cursor;
         v_sql      VARCHAR2(4000);

         v_tt_nb tt_nb;
         v_debit tt_debit2;
         
         v_h_deb   NUMBER;
         v_h_fin   NUMBER;
         v_d_deb   DATE;
         v_d_fin   DATE;
         v_qte     NUMBER;
         
         v_pos    pls_integer; 
         
         v_dat_min DATE;
         v_dat_max DATE; 
    BEGIN
        IF v_hmax>24 THEN
            v_hmax:=24;
        ELSIF v_hmax <= 0 THEN
            v_hmax := 1;        
        END IF;
        
        IF v_hmin>24 THEN
            v_hmin:=23;
        ELSIF v_hmin <= 0 THEN
            v_hmin := 0;        
        END IF;
        
        -- init tableau de minutes
        init_tt_nb(v_tt_nb, v_hmin, v_hmax);
                 
        v_sql := 'SELECT ' || p_col_qte || ', to_number(to_char('||p_col_time||', ''HH24MI'')) h, to_number(to_char('||p_col_time_2||', ''HH24MI'')) h2, '||p_col_time||',' ||p_col_time_2 ||' '||
                  'FROM '||p_table||' '|| 
                  'WHERE '||p_col_time||' <= :p_dat_max ' ||
                    'AND '||p_col_time_2||' >= :p_dat_min ';
                  
        IF p_where IS NOT NULL THEN
           v_sql := v_sql||' AND '||p_where;
        END IF;
                  
        v_sql := v_sql||' order by 3'; 
        
        IF v_hmin=0 THEN
            v_dat_min := trunc(p_jour);
        ELSE
            v_dat_min := to_date(to_char(p_jour, 'YYYYMMDD')||lpad(v_hmin, 2, 0)||'00', 'YYYYMMDDHH24MI');
        END IF;   
        
        IF v_hmax=24 then
            v_dat_max := trunc(p_jour) + 1;
        ELSE
            v_dat_max := to_date(to_char(p_jour, 'YYYYMMDD')||lpad(v_hmax, 2, 0)||'00', 'YYYYMMDDHH24MI');
        END IF;
         
        -- remplissage tableau minutes en cumulant les qte 
        OPEN v_cursor FOR v_sql USING v_dat_max, v_dat_min;
        LOOP
            FETCH v_cursor INTO v_qte, v_h_deb, v_h_fin, v_d_deb, v_d_fin;
            EXIT WHEN v_cursor%NOTFOUND;
            
            IF v_d_deb < to_date(to_char(p_jour, 'YYYYMMDD')||lpad(v_hmin, 2, 0)||'00', 'YYYYMMDDHH24MI') THEN 
                v_h_deb:=v_hmin*100;
            ELSIF v_hmax=24 THEN
                IF v_d_deb > (trunc(p_jour) + 1) THEN 
                    v_h_deb:=2359;
                END IF;
            ELSIF v_d_deb >= to_date(to_char(p_jour, 'YYYYMMDD')||lpad(v_hmax, 2, 0)||'00', 'YYYYMMDDHH24MI') THEN 
                v_h_deb:=((v_hmax-1)*100)+59;
            END IF;
            
            IF v_d_fin < to_date(to_char(p_jour, 'YYYYMMDD')||lpad(v_hmin, 2, 0)||'00', 'YYYYMMDDHH24MI') THEN 
                v_h_fin:=v_hmin*100;
            ELSIF v_hmax=24 THEN
                IF v_d_fin > (trunc(p_jour) + 1) THEN 
                    v_h_fin:=2359;
                END IF;
            ELSIF v_d_fin >= to_date(to_char(p_jour, 'YYYYMMDD')||lpad(v_hmax, 2, 0)||'00', 'YYYYMMDDHH24MI') THEN 
                v_h_fin:=((v_hmax-1)*100)+59;
            END IF;
             
            v_pos := v_h_deb;             
            WHILE v_pos IS NOT NULL LOOP
               v_tt_nb(v_pos) := v_tt_nb(v_pos) + v_qte; 
               
               v_pos := v_tt_nb.next(v_pos);
               
               EXIT WHEN v_pos >= v_h_fin; 
            END LOOP;               
        END LOOP;
        
        -- boucle tableau minute pour remplissage tableau des débits et pipe row
        v_pos := v_tt_nb.first; 
        WHILE v_pos IS NOT NULL LOOP
            v_debit(v_pos).date_trait    := to_date(to_char(p_jour, 'YYYYMMDD')||lpad(v_pos, 4, 0), 'YYYYMMDDHH24MI');
            v_debit(v_pos).debit         := 0;
            v_debit(v_pos).total         := v_tt_nb(v_pos);
            
            PIPE ROW(v_debit(v_pos));
                
            v_pos := v_tt_nb.next(v_pos); 
        END LOOP;
    END;  
    
    ------------------------------------------------------------------------------
    -- fonction débit générale 
    ------------------------------------------------------------------------------
    FUNCTION qte_plage_date_sec(p_table         VARCHAR2,
                           p_col_time       VARCHAR,
                           p_col_time_2     VARCHAR,
                           p_jour           DATE,
                           p_hmin           number,
                           p_hmax           number,
                           p_where          VARCHAR2,
                           p_col_qte        VARCHAR2 DEFAULT '1') RETURN tt_debit PIPELINED IS
         v_hmin NUMBER := least(NVL(p_hmin,0), NVL(p_hmax,24));                                              
         v_hmax NUMBER := greatest(NVL(p_hmin,0), NVL(p_hmax,24));

         type type_ref_cursor IS REF CURSOR; 

         v_cursor   type_ref_cursor;
         v_sql      VARCHAR2(4000);

         v_tt_nb tt_nb;
         v_debit tt_debit2;
         
         v_h_deb   NUMBER;
         v_h_fin   NUMBER;
         v_d_deb   DATE;
         v_d_fin   DATE;
         v_qte     NUMBER;
         
         v_pos    pls_integer; 
         
         v_dat_min DATE;
         v_dat_max DATE; 
    BEGIN
        IF v_hmax>24 THEN
            v_hmax:=24;
        ELSIF v_hmax <= 0 THEN
            v_hmax := 1;        
        END IF;
        
        IF v_hmin>24 THEN
            v_hmin:=23;
        ELSIF v_hmin <= 0 THEN
            v_hmin := 0;        
        END IF;
        
        -- init tableau de secondes
        init_tt_nb_sec(v_tt_nb, v_hmin, v_hmax);
        
        v_sql := 'SELECT ' || p_col_qte || ', to_number(to_char('||p_col_time||', ''HH24MISS'')) h, to_number(to_char('||p_col_time_2||', ''HH24MISS'')) h2, '||p_col_time||',' ||p_col_time_2 ||' '||
                  'FROM '||p_table||' '|| 
                  'WHERE '||p_col_time||' <= :p_dat_max ' ||
                    'AND '||p_col_time_2||' >= :p_dat_min ';
                  
        IF p_where IS NOT NULL THEN
           v_sql := v_sql||' AND '||p_where;
        END IF;
                  
        v_sql := v_sql||' order by 3'; 
        
        IF v_hmin=0 THEN
            v_dat_min := trunc(p_jour);
        ELSE
            v_dat_min := to_date(to_char(p_jour, 'YYYYMMDD')||lpad(v_hmin, 2, 0)||'00', 'YYYYMMDDHH24MI');
        END IF;   
        
        IF v_hmax=24 then
            v_dat_max := trunc(p_jour) + 1;
        ELSE
            v_dat_max := to_date(to_char(p_jour, 'YYYYMMDD')||lpad(v_hmax, 2, 0)||'00', 'YYYYMMDDHH24MI');
        END IF;   
        
        -- remplissage tableau minutes en cumulant les qte 
        OPEN v_cursor FOR v_sql USING v_dat_max, v_dat_min;         
        LOOP
            FETCH v_cursor INTO v_qte, v_h_deb, v_h_fin, v_d_deb, v_d_fin;
            EXIT WHEN v_cursor%NOTFOUND;
            
            IF v_d_deb < to_date(to_char(p_jour, 'YYYYMMDD')||lpad(v_hmin, 2, 0)||'00', 'YYYYMMDDHH24MI') THEN 
                v_h_deb:=v_hmin*10000;
            ELSIF v_hmax=24 THEN
                IF v_d_deb > (trunc(p_jour) + 1) THEN 
                    v_h_deb:=235959;
                END IF;
            ELSIF v_d_deb >= to_date(to_char(p_jour, 'YYYYMMDD')||lpad(v_hmax, 2, 0)||'00', 'YYYYMMDDHH24MI') THEN 
                v_h_deb:=((v_hmax-1)*10000)+5959;
            END IF;
            
            IF v_d_fin < to_date(to_char(p_jour, 'YYYYMMDD')||lpad(v_hmin, 2, 0)||'00', 'YYYYMMDDHH24MI') THEN 
                v_h_fin:=v_hmin*10000;
            ELSIF v_hmax=24 THEN
                IF v_d_fin > (trunc(p_jour) + 1) THEN 
                    v_h_fin:=235959;
                END IF;
            ELSIF v_d_fin >= to_date(to_char(p_jour, 'YYYYMMDD')||lpad(v_hmax, 2, 0)||'00', 'YYYYMMDDHH24MI') THEN 
                v_h_fin:=((v_hmax-1)*10000)+5959;
            END IF;
             
            v_pos := v_h_deb;             
            WHILE v_pos IS NOT NULL LOOP
               v_tt_nb(v_pos) := v_tt_nb(v_pos) + v_qte; 
               
               v_pos := v_tt_nb.next(v_pos);
               
               EXIT WHEN v_pos >= v_h_fin; 
            END LOOP;               
        END LOOP;
       
        -- boucle tableau minute pour remplissage tableau des débits et pipe row
        v_pos := v_tt_nb.first; 
        WHILE v_pos IS NOT NULL LOOP
            v_debit(v_pos).date_trait    := to_date(to_char(p_jour, 'YYYYMMDD')||lpad(v_pos, 6, 0), 'YYYYMMDDHH24MISS');
            v_debit(v_pos).debit         := 0;
            v_debit(v_pos).total         := v_tt_nb(v_pos);
            
            PIPE ROW(v_debit(v_pos));
                
            v_pos := v_tt_nb.next(v_pos); 
        END LOOP;
    END;  
    
    
      
END;
/
show errors;